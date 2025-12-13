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
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var shouldKeepRunning = false
    private var smoothedAudioLevel: Double = 0
    private var restartTask: Task<Void, Never>?

    func start(localeIdentifier: String = "ja-JP") {
        guard !isRunning else { return }
        lastErrorMessage = nil
        shouldKeepRunning = true
        restartTask?.cancel()
        restartTask = nil

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
        restartTask?.cancel()
        restartTask = nil
        stopRecording()
        partialText = ""
        finalText = ""
        audioLevel = 0
        lastErrorMessage = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // ignore
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
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw TranscriberError.audioSessionSetupFailed(error.localizedDescription)
        }
    }

    private func startRecording(localeIdentifier: String) throws {
        stopRecording()

        let locale = Locale(identifier: localeIdentifier)
        let recognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer, recognizer.isAvailable else {
            throw TranscriberError.recognizerUnavailable
        }
        speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.recognitionRequest?.append(buffer)
            self.updateAudioLevel(from: buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

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

    private func stopRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        isRunning = false
    }

    private func restartIfNeeded() {
        guard shouldKeepRunning else { return }

        restartTask?.cancel()
        restartTask = Task { @MainActor in
            stopRecording()
            try? await Task.sleep(for: .milliseconds(250))
            guard shouldKeepRunning else { return }
            do {
                try startRecording(localeIdentifier: speechRecognizer?.locale.identifier ?? "ja-JP")
            } catch {
                lastErrorMessage = error.localizedDescription
                shouldKeepRunning = false
                stopRecording()
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

        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = self?.smoothedAudioLevel ?? 0
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
