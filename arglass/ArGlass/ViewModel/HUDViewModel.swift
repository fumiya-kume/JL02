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

    let cameraService: CameraServiceProtocol
    let locationService: LocationServiceProtocol
    private let vlmAPIClient: VLMAPIClientProtocol
    private let historyService: HistoryServiceProtocol

    private var startupTask: Task<Void, Never>?
    private var inferenceTask: Task<Void, Never>?

    private let inferenceInterval: Duration = .seconds(4)
    private let retryInterval: Duration = .seconds(1)
    private var consecutiveErrorCount: Int = 0
    private let maxRetries: Int = 3

    init(
        cameraService: CameraServiceProtocol? = nil,
        locationService: LocationServiceProtocol? = nil,
        vlmAPIClient: VLMAPIClientProtocol = VLMAPIClient.shared,
        historyService: HistoryServiceProtocol = HistoryService.shared
    ) {
        self.cameraService = cameraService ?? CameraService()
        self.locationService = locationService ?? LocationService()
        self.vlmAPIClient = vlmAPIClient
        self.historyService = historyService
    }

    func start() {
        startAutoInference()
    }

    func stop() {
        stopAutoInference()
        startupTask?.cancel()
        startupTask = nil
        cameraService.stop()
        locationService.stopUpdating()
    }

    func startAutoInference() {
        guard !isAutoInferenceEnabled else { return }
        isAutoInferenceEnabled = true
        locationService.requestAuthorization()
        ensureCameraRunning()
        inferenceTask?.cancel()
        inferenceTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let success = await self.performInference()
                if success {
                    self.consecutiveErrorCount = 0
                    try? await Task.sleep(for: self.inferenceInterval)
                } else {
                    self.consecutiveErrorCount += 1
                    if self.consecutiveErrorCount < self.maxRetries {
                        try? await Task.sleep(for: self.retryInterval)
                        continue
                    }

                    self.consecutiveErrorCount = 0
                    print("[VLM] Max retries (\(self.maxRetries)) reached, waiting before next attempt")
                    try? await Task.sleep(for: self.inferenceInterval)
                }
            }
        }
    }

    func stopAutoInference() {
        isAutoInferenceEnabled = false
        consecutiveErrorCount = 0
        inferenceTask?.cancel()
        inferenceTask = nil
        locationService.stopUpdating()
        if !isCameraPreviewEnabled {
            cameraService.stop()
        }
    }

    func toggleCameraPreview() {
        isCameraPreviewEnabled.toggle()

        if isCameraPreviewEnabled || isAutoInferenceEnabled {
            ensureCameraRunning()
        } else {
            cameraService.stop()
        }
    }

    private func ensureCameraRunning() {
        startupTask?.cancel()
        startupTask = Task { [weak self] in
            guard let self else { return }
            await self.cameraService.requestAccessAndStart()
        }
    }

    func performInference() async -> Bool {
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
            let landmark = try await vlmAPIClient.inferLandmark(
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
                await historyService.addEntry(entry, image: image)
            }

            return true
        } catch {
            apiRequestState = .error(message: error.localizedDescription)
            errorMessage = error.localizedDescription
            print(errorMessage)
            return false
        }
    }
}
