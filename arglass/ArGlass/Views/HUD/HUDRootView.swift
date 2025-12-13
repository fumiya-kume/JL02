import SwiftUI

struct HUDRootView: View {
    @ObservedObject var viewModel: HUDViewModel

    @State private var glitchIntensity: CGFloat = 0
    @State private var captureFlashIntensity: CGFloat = 0
    @State private var showingHistory = false
    @State private var showingImageViewer = false

    @StateObject private var speechTranscriber = SpeechTranscriber()
    @State private var isVoiceInputEnabled = false
    @State private var voiceQueryText = ""
    @State private var isVoiceSending = false
    @State private var voiceCooldownUntil = Date.distantPast
    @State private var autoInferenceWasEnabledBeforeVoice = false
    @State private var queryClearToken = UUID()

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
                subtitle: currentSubtitle,
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

    private var currentSubtitle: String? {
        if case .locked(let landmark, _) = viewModel.recognitionState {
            return landmark.subtitle
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
            .padding(.bottom, safeAreaInsets.bottom + 24)
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
        Task {
            await viewModel.cameraService.requestAccessAndStart()
        }

        speechTranscriber.start(localeIdentifier: "ja-JP")
    }

    private func stopVoiceInputMode() {
        speechTranscriber.stop()
        cancelQueryClear()
        voiceQueryText = ""
        isVoiceSending = false

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
}

#Preview {
    HUDRootView(viewModel: HUDViewModel())
}
