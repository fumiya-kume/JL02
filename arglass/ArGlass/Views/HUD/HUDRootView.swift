import AVFoundation
import NaturalLanguage
import SwiftUI

struct HUDRootView: View {
    @ObservedObject var viewModel: HUDViewModel

    @State private var glitchIntensity: CGFloat = 0
    @State private var captureFlashIntensity: CGFloat = 0
    @State private var showingHistory = false
    @State private var showingImageViewer = false

    @StateObject private var speechTranscriber = SpeechTranscriber()
    @StateObject private var speechSpeaker = SpeechSpeaker()
    @State private var isVoiceInputEnabled = false
    @State private var voiceQueryText = ""
    @State private var isVoiceSending = false
    @State private var voiceCooldownUntil = Date.distantPast
    @State private var autoInferenceWasEnabledBeforeVoice = false
    @State private var queryClearToken = UUID()
    @State private var lastSpokenLandmarkID: UUID?
    @State private var cameraStartTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                ScanlinesOverlay()
                    .opacity(0.20)

                GlitchOverlay(intensity: glitchIntensity)

                CaptureFlashOverlay(intensity: captureFlashIntensity)

                overlay(safeAreaInsets: geometry.safeAreaInsets)

                if isVoiceInputEnabled {
                    SiriListeningOverlay(level: speechTranscriber.audioLevel)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onChange(of: viewModel.recognitionState) { _, newValue in
            if case .locked = newValue {
                triggerCaptureFlash()
                triggerGlitch()
            }

            let preferences = UserPreferencesManager.shared.load()
            guard isVoiceInputEnabled || preferences.isReadAloudEnabled else { return }
            guard case let .locked(target, _) = newValue else { return }
            guard lastSpokenLandmarkID != target.id else { return }

            lastSpokenLandmarkID = target.id
            speakInferenceResult(target: target)
        }
        .onChange(of: isVoiceInputEnabled) { _, enabled in
            enabled ? startVoiceInputMode() : stopVoiceInputMode()
        }
        .onChange(of: speechTranscriber.partialText) { _, newValue in
            guard isVoiceInputEnabled else { return }
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            cancelQueryClear()
            voiceQueryText = trimmed
            
            // ? が含まれている場合は即座に音声認識を終了させて確定
            if trimmed.contains("?") || trimmed.contains("？") {
                speechTranscriber.finalizeCurrentText()
            }
        }
        .onChange(of: speechTranscriber.finalText) { _, newValue in
            guard isVoiceInputEnabled else { return }
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            voiceQueryText = trimmed
            scheduleQueryClear(afterSeconds: 12)

            guard isQuestionLike(trimmed) else { return }
            triggerAutoSendIfPossible(text: trimmed)
        }
        .onChange(of: viewModel.apiRequestState) { _, newValue in
            guard isVoiceInputEnabled else { return }
            guard case .requesting = newValue else { return }
            
            voiceQueryText = ""
            cancelQueryClear()
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            speechTranscriber.stop()
            viewModel.stop()
        }
        .fullScreenCover(isPresented: $showingHistory) {
            HistoryView()
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            ImageViewerView(
                image: viewModel.lastCapturedImage,
                description: currentDescription,
                captureOrientation: viewModel.lastCaptureOrientation
            )
        }
    }

    private var phaseKey: Int {
        switch viewModel.recognitionState {
        case .searching:
            0
        case .scanning:
            1
        case .locked:
            2
        }
    }

    private var currentDescription: String? {
        if case .locked(let landmark, _) = viewModel.recognitionState {
            return landmark.description
        }
        return nil
    }

    @ViewBuilder
    private var background: some View {
        if viewModel.isCameraPreviewEnabled {
            CameraPreviewView(session: viewModel.cameraService.session)
        } else {
            Color.black
        }
    }

    private var historyButton: some View {
        Button(action: { showingHistory = true }) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.90))
                .hudTopCapsuleStyle()
        }
        .contentShape(Capsule())
    }

    private func overlay(safeAreaInsets: EdgeInsets) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    historyButton

#if DEBUG
                    DebugStatusOverlay(viewModel: viewModel)
#endif

                    Spacer(minLength: 0)

#if DEBUG
                    HUDDebugMenu(viewModel: viewModel, isVoiceInputEnabled: $isVoiceInputEnabled)
#endif
                }

                if isVoiceInputEnabled {
                    HUDQueryBarView(
                        text: $voiceQueryText,
                        isListening: speechTranscriber.isRunning,
                        isSending: isVoiceSending
                    )
                }
            }
            .padding(.top, safeAreaInsets.top + 16)
            .hudHorizontalPadding(safeAreaInsets)

            Spacer()

            TargetMarkerView(recognitionState: viewModel.recognitionState)
                .hudHorizontalPadding(safeAreaInsets)

            Spacer()

            HologramPanelView(
                recognitionState: viewModel.recognitionState,
                capturedImage: viewModel.lastCapturedImage,
                captureOrientation: viewModel.lastCaptureOrientation,
                onImageTap: { showingImageViewer = true }
            )
            .hudHorizontalPadding(safeAreaInsets)
            .padding(.bottom, max(safeAreaInsets.bottom, 34) + 42)
        }
        .animation(.easeInOut(duration: 0.25), value: phaseKey)
    }

    private func triggerGlitch() {
        glitchIntensity = 1
        withAnimation(.easeOut(duration: 0.65)) {
            glitchIntensity = 0
        }
    }

    private func triggerCaptureFlash() {
        captureFlashIntensity = 1
        withAnimation(.easeOut(duration: 0.4)) {
            captureFlashIntensity = 0
        }
    }

    private func startVoiceInputMode() {
        cancelQueryClear()
        voiceQueryText = ""
        isVoiceSending = false
        voiceCooldownUntil = .distantPast

        autoInferenceWasEnabledBeforeVoice = viewModel.isAutoInferenceEnabled
        viewModel.stopAutoInference()

        viewModel.locationService.requestAuthorization()
        cameraStartTask = Task {
            await viewModel.cameraService.requestAccessAndStart()
        }

        speechTranscriber.start(localeIdentifier: "ja-JP")
    }

    private func stopVoiceInputMode() {
        cameraStartTask?.cancel()
        cameraStartTask = nil
        speechTranscriber.stop()
        cancelQueryClear()
        voiceQueryText = ""
        isVoiceSending = false
        lastSpokenLandmarkID = nil
        speechSpeaker.stop()

        if autoInferenceWasEnabledBeforeVoice {
            autoInferenceWasEnabledBeforeVoice = false
            viewModel.startAutoInference()
        } else {
            autoInferenceWasEnabledBeforeVoice = false
            viewModel.locationService.stopUpdating()
            if !viewModel.isCameraPreviewEnabled {
                viewModel.cameraService.stop()
            }
        }
    }

    private func triggerAutoSendIfPossible(text: String) {
        guard !isVoiceSending else { return }
        guard Date() >= voiceCooldownUntil else { return }

        isVoiceSending = true

        Task {
            _ = await viewModel.performInference(text: text)
            await MainActor.run {
                isVoiceSending = false
                voiceCooldownUntil = Date().addingTimeInterval(1.5)
            }
        }
    }

    private func isQuestionLike(_ text: String) -> Bool {
        if text.contains("?") || text.contains("？") {
            return true
        }

        let keywords = [
            "何", "どこ", "いつ", "誰", "どう", "なぜ", "どんな",
            "教えて", "説明", "ですか", "ますか", "かな",
        ]
        return keywords.contains { text.contains($0) }
    }

    private func scheduleQueryClear(afterSeconds seconds: Double) {
        let token = UUID()
        queryClearToken = token
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard queryClearToken == token else { return }
            guard isVoiceInputEnabled else { return }
            voiceQueryText = ""
        }
    }

    private func cancelQueryClear() {
        queryClearToken = UUID()
    }

    private func detectLanguage(for text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let detectedLanguage = recognizer.dominantLanguage else {
            let preferences = UserPreferencesManager.shared.load()
            return preferences.language.speechLocaleIdentifier
        }

        return languageToSpeechLocale(detectedLanguage)
    }

    private func languageToSpeechLocale(_ language: NLLanguage) -> String {
        switch language {
        case .japanese: return "ja-JP"
        case .english: return "en-US"
        case .simplifiedChinese, .traditionalChinese: return "zh-CN"
        case .korean: return "ko-KR"
        case .spanish: return "es-ES"
        case .french: return "fr-FR"
        case .german: return "de-DE"
        case .thai: return "th-TH"
        default:
            let preferences = UserPreferencesManager.shared.load()
            return preferences.language.speechLocaleIdentifier
        }
    }

    private func speakInferenceResult(target: Landmark) {
        // 読み上げ中に自分の音声を拾って暴発しないよう、認識を一時停止してから読み上げる
        speechTranscriber.pause()

        let speakText: String
        if target.description.isEmpty {
            speakText = target.name
        } else {
            speakText = "\(target.name)。\(target.description)"
        }

        let detectedLocale = detectLanguage(for: speakText)

        speechSpeaker.speak(text: speakText, language: detectedLocale) {
            guard self.isVoiceInputEnabled else { return }
            // TTS終了直後のレースコンディションを避けるため、短いディレイを入れてから再開
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                guard self.isVoiceInputEnabled else { return }
                self.speechTranscriber.resume(localeIdentifier: "ja-JP")
            }
        }
    }
}

#if DEBUG
#Preview {
    HUDRootView(viewModel: HUDViewModel())
}
#endif

@MainActor
private final class SpeechSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
        if #available(iOS 13.0, *) {
            synthesizer.usesApplicationAudioSession = true
        }
    }

    func speak(text: String, language: String, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    func stop() {
        onFinish = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let callback = self.onFinish
            self.onFinish = nil
            callback?()
        }
    }
}
