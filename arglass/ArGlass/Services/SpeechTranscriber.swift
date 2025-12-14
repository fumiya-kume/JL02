import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechTranscriber: ObservableObject {
    enum TranscriberError: LocalizedError {
        case speechNotAuthorized
        case microphoneNotAuthorized
        case recognizerUnavailable
        case audioSessionSetupFailed(String)

        var errorDescription: String? {
            switch self {
            case .speechNotAuthorized:
                return "音声認識の権限がありません"
            case .microphoneNotAuthorized:
                return "マイクの権限がありません"
            case .recognizerUnavailable:
                return "音声認識が利用できません"
            case .audioSessionSetupFailed(let message):
                return "オーディオセッションの初期化に失敗しました: \(message)"
            }
        }
    }

    @Published private(set) var isRunning = false
    @Published private(set) var partialText: String = ""
    @Published private(set) var finalText: String = ""
    @Published private(set) var audioLevel: Double = 0
    @Published private(set) var lastErrorMessage: String?

    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    // SFSpeechAudioBufferRecognitionRequest.append(_:) is thread-safe, and the audio tap callback
    // is invoked on a non-MainActor context.
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isTapInstalled = false

    private var shouldKeepRunning = false
    private var isPaused = false
    private var smoothedAudioLevel: Double = 0
    private var restartTask: Task<Void, Never>?
    private var interruptionObserver: NSObjectProtocol?
    private var mediaServicesResetObserver: NSObjectProtocol?

    func start(localeIdentifier: String = "ja-JP") {
        guard !isRunning else { return }
        lastErrorMessage = nil
        shouldKeepRunning = true
        isPaused = false
        restartTask?.cancel()
        restartTask = nil

        setupAudioSessionObservers()

        Task {
            do {
                try await preparePermissions()
                try configureAudioSession()
                try startRecording(localeIdentifier: localeIdentifier)
            } catch {
                lastErrorMessage = error.localizedDescription
                shouldKeepRunning = false
                stopRecording()
            }
        }
    }

    func stop() {
        shouldKeepRunning = false
        isPaused = false
        restartTask?.cancel()
        restartTask = nil
        stopRecording()
        partialText = ""
        finalText = ""
        audioLevel = 0
        lastErrorMessage = nil

        removeAudioSessionObservers()

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // ignore
        }
    }

    /// 現在のpartialTextをfinalTextとして確定させ、音声認識を再開する
    func finalizeCurrentText() {
        guard isRunning, !partialText.isEmpty else { return }
        finalText = partialText
        restartIfNeeded()
    }

    /// 音声入力モードは維持したまま、認識だけ一時停止する（読み上げ時など）
    func pause() {
        isPaused = true
        restartTask?.cancel()
        restartTask = nil
        stopRecording()
    }

    /// pause()で停止した音声認識を再開する
    func resume(localeIdentifier: String = "ja-JP") {
        guard shouldKeepRunning else { return }
        guard isPaused else { return }
        
        isPaused = false
        restartTask?.cancel()
        restartTask = nil
        
        Task {
            do {
                try configureAudioSession()
                try startRecording(localeIdentifier: localeIdentifier)
            } catch {
                lastErrorMessage = error.localizedDescription
                shouldKeepRunning = false
                stopRecording()
            }
        }
    }

    private func preparePermissions() async throws {
        let speechStatus = await requestSpeechAuthorizationIfNeeded()
        guard speechStatus == .authorized else {
            throw TranscriberError.speechNotAuthorized
        }

        let micGranted = await requestMicrophonePermissionIfNeeded()
        guard micGranted else {
            throw TranscriberError.microphoneNotAuthorized
        }
    }

    private func requestSpeechAuthorizationIfNeeded() async -> SFSpeechRecognizerAuthorizationStatus {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        guard currentStatus == .notDetermined else { return currentStatus }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophonePermissionIfNeeded() async -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // 読み上げ（再生）と音声認識（録音）を同居させるため playAndRecord を使用する
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw TranscriberError.audioSessionSetupFailed(error.localizedDescription)
        }
    }

    private func startRecording(localeIdentifier: String) throws {
        stopRecognition()

        let locale = Locale(identifier: localeIdentifier)
        let recognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer, recognizer.isAvailable else {
            throw TranscriberError.recognizerUnavailable
        }
        speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        try ensureAudioEngineRunning()

        isRunning = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.partialText = text

                    if result.isFinal {
                        self.finalText = text
                        self.partialText = text
                        self.restartIfNeeded()
                        return
                    }
                }

                if error != nil {
                    self.restartIfNeeded()
                }
            }
        }
    }

    private func ensureAudioEngineRunning() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        if !isTapInstalled {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                Task { @MainActor [weak self] in
                    self?.updateAudioLevel(from: buffer)
                }
            }
            isTapInstalled = true
        }

        guard !audioEngine.isRunning else { return }
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func stopRecording() {
        stopRecognition()

        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()

        audioLevel = 0
        smoothedAudioLevel = 0
        isRunning = false
    }

    private func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = recognitionRequest
        recognitionRequest = nil
        request?.endAudio()
    }

    private func restartIfNeeded() {
        guard shouldKeepRunning else { return }
        guard !isPaused else { return }

        restartTask?.cancel()
        restartTask = Task { @MainActor in
            stopRecognition()
            try? await Task.sleep(for: .milliseconds(60))
            guard shouldKeepRunning else { return }
            guard !isPaused else { return }
            do {
                try configureAudioSession()
                try ensureAudioEngineRunning()
                try startRecording(localeIdentifier: speechRecognizer?.locale.identifier ?? "ja-JP")
            } catch {
                lastErrorMessage = error.localizedDescription
                // Keep voice mode alive; retry a bit later in case the recognizer is temporarily unavailable.
                try? await Task.sleep(for: .milliseconds(600))
                self.restartIfNeeded()
            }
        }
    }

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        var sum: Double = 0
        for i in 0..<frameCount {
            let sample = Double(channelData[i])
            sum += sample * sample
        }

        let rms = sqrt(sum / Double(frameCount))
        let db = rms > 0 ? 20.0 * log10(rms) : -80.0

        let normalized = ((db + 55.0) / 55.0).clamped(to: 0...1)
        smoothedAudioLevel = (smoothedAudioLevel * 0.80) + (normalized * 0.20)
        audioLevel = smoothedAudioLevel
    }

    private func setupAudioSessionObservers() {
        removeAudioSessionObservers()

        let notificationCenter = NotificationCenter.default

        interruptionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }

        mediaServicesResetObserver = notificationCenter.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMediaServicesReset()
        }
    }

    private func removeAudioSessionObservers() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        if let observer = mediaServicesResetObserver {
            NotificationCenter.default.removeObserver(observer)
            mediaServicesResetObserver = nil
        }
    }

    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // 割り込み開始時は何もしない（pause()が呼ばれている可能性がある）
            break
        case .ended:
            // 割り込み終了時、復帰可能なら再開
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                Task { @MainActor in
                    guard self.shouldKeepRunning else { return }
                    guard !self.isPaused else { return }
                    // 短いディレイを入れてから復帰
                    try? await Task.sleep(for: .milliseconds(100))
                    guard self.shouldKeepRunning else { return }
                    guard !self.isPaused else { return }
                    self.restartIfNeeded()
                }
            }
        @unknown default:
            break
        }
    }

    private func handleMediaServicesReset() {
        // メディアサービスリセット時は、実行中なら再初期化が必要
        guard shouldKeepRunning else { return }
        guard !isPaused else { return }

        Task { @MainActor in
            // 既存の録音を停止
            stopRecording()
            // 短いディレイ後に再開を試みる
            try? await Task.sleep(for: .milliseconds(500))
            guard shouldKeepRunning else { return }
            guard !isPaused else { return }
            do {
                try configureAudioSession()
                try startRecording(localeIdentifier: speechRecognizer?.locale.identifier ?? "ja-JP")
            } catch {
                lastErrorMessage = error.localizedDescription
                shouldKeepRunning = false
                stopRecording()
            }
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
