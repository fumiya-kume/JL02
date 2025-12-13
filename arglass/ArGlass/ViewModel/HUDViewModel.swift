import Foundation
import SwiftUI

@MainActor
final class HUDViewModel: ObservableObject {
    enum RecognitionState: Equatable {
        case searching
        case scanning(candidate: Landmark, progress: Double)
        case locked(target: Landmark, confidence: Double)
    }

    enum APIRequestState: Equatable {
        case idle
        case requesting
        case success(responseTime: TimeInterval)
        case error(message: String)
    }

    enum CaptureState: Equatable {
        case idle
        case captured(imageSizeKB: Double)
        case failed
    }

    @Published var recognitionState: RecognitionState = .searching
    @Published var isConnected: Bool = true
    @Published var isAutoInferenceEnabled: Bool = false
    @Published var apiRequestState: APIRequestState = .idle
    @Published var captureState: CaptureState = .idle
    @Published var errorMessage: String = ""
    @Published var isCameraPreviewEnabled: Bool = true
    @Published var lastCapturedImage: UIImage?

    let cameraService = CameraService()
    let locationService = LocationService()

    private var startupTask: Task<Void, Never>?
    private var inferenceTask: Task<Void, Never>?

    private let inferenceInterval: TimeInterval = 4.0
    private var consecutiveErrorCount: Int = 0
    private let maxRetries: Int = 3

    func start() {
        startupTask?.cancel()
        startupTask = Task { [weak self] in
            guard let self else { return }
            await self.cameraService.requestAccessAndStart()
            self.locationService.requestAuthorization()
            self.startAutoInference()
        }
    }

    func stop() {
        startupTask?.cancel()
        inferenceTask?.cancel()
        startupTask = nil
        inferenceTask = nil
        cameraService.stop()
        locationService.stopUpdating()
    }

    func startAutoInference() {
        guard !isAutoInferenceEnabled else { return }
        isAutoInferenceEnabled = true
        inferenceTask?.cancel()
        inferenceTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let success = await self.performInference()
                if success {
                    self.consecutiveErrorCount = 0
                    try? await Task.sleep(for: .seconds(self.inferenceInterval))
                } else {
                    self.consecutiveErrorCount += 1
                    if self.consecutiveErrorCount >= self.maxRetries {
                        self.consecutiveErrorCount = 0
                        print("[VLM] Max retries (\(self.maxRetries)) reached, waiting before next attempt")
                        try? await Task.sleep(for: .seconds(self.inferenceInterval))
                    }
                }
            }
        }
    }

    func stopAutoInference() {
        isAutoInferenceEnabled = false
        inferenceTask?.cancel()
        inferenceTask = nil
    }

    private func performInference() async -> Bool {
        guard let image = cameraService.captureCurrentFrame() else {
            captureState = .failed
            errorMessage = "カメラからの画像取得に失敗しました"
            print(errorMessage)
            return false
        }

        let jpegData = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: image.jpegData(compressionQuality: 0.8))
            }
        }

        guard let jpegData else {
            captureState = .failed
            errorMessage = "画像のJPEG変換に失敗しました"
            print(errorMessage)
            return false
        }

        let sizeKB = Double(jpegData.count) / 1024.0
        captureState = .captured(imageSizeKB: sizeKB)
        apiRequestState = .requesting

        let startTime = Date()

        do {
            let interests = OnboardingViewModel.getSelectedInterests()
            let landmark = try await VLMAPIClient.shared.inferLandmark(
                jpegData: jpegData,
                locationInfo: locationService.currentLocation,
                interests: interests
            )
            let elapsed = Date().timeIntervalSince(startTime)
            apiRequestState = .success(responseTime: elapsed)
            let confidence = 0.88 + Double.random(in: 0.0...0.10)
            recognitionState = .locked(target: landmark, confidence: min(confidence, 0.99))
            lastCapturedImage = image

            Task {
                let entry = HistoryEntry(landmark: landmark)
                await HistoryService.shared.addEntry(entry, image: image)
            }

            return true
        } catch {
            apiRequestState = .error(message: error.localizedDescription)
            errorMessage = error.localizedDescription
            print(errorMessage)
            return false
        }
    }

    func setSearching() {
        recognitionState = .searching
        lastCapturedImage = nil
    }

    func setScanning(candidate: Landmark, progress: Double) {
        recognitionState = .scanning(candidate: candidate, progress: max(0, min(progress, 1)))
    }

    func setLocked(target: Landmark, confidence: Double) {
        recognitionState = .locked(target: target, confidence: max(0, min(confidence, 0.99)))
    }
}
