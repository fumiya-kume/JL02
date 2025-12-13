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

    let cameraService = CameraService()

    private var startupTask: Task<Void, Never>?
    private var simulationTask: Task<Void, Never>?
    private var inferenceTask: Task<Void, Never>?

    private let inferenceInterval: TimeInterval = 4.0

    func start() {
        startupTask?.cancel()
        startupTask = Task { [weak self] in
            guard let self else { return }
            await self.cameraService.requestAccessAndStart()
        }
    }

    func stop() {
        startupTask?.cancel()
        simulationTask?.cancel()
        inferenceTask?.cancel()
        startupTask = nil
        simulationTask = nil
        inferenceTask = nil
        cameraService.stop()
    }

    func startAutoInference() {
        guard !isAutoInferenceEnabled else { return }
        isAutoInferenceEnabled = true
        inferenceTask?.cancel()
        inferenceTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.performInference()
                try? await Task.sleep(for: .seconds(self.inferenceInterval))
            }
        }
    }

    func stopAutoInference() {
        isAutoInferenceEnabled = false
        inferenceTask?.cancel()
        inferenceTask = nil
    }

    private func performInference() async {
        guard let image = cameraService.captureCurrentFrame() else {
            captureState = .failed
            errorMessage = "カメラからの画像取得に失敗しました"
            print(errorMessage)
            return
        }

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let sizeKB = Double(imageData.count) / 1024.0
            captureState = .captured(imageSizeKB: sizeKB)
        }

        recognitionState = .searching
        apiRequestState = .requesting

        let startTime = Date()

        do {
            let landmark = try await VLMAPIClient.shared.inferLandmark(image: image)
            let elapsed = Date().timeIntervalSince(startTime)
            apiRequestState = .success(responseTime: elapsed)
            let confidence = 0.88 + Double.random(in: 0.0...0.10)
            recognitionState = .locked(target: landmark, confidence: min(confidence, 0.99))

            // Return to searching state after displaying the result
            try? await Task.sleep(for: .seconds(5))
            if case .locked = recognitionState {
                recognitionState = .searching
            }
        } catch {
            apiRequestState = .error(message: error.localizedDescription)
            recognitionState = .searching
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }

    func setSearching() {
        cancelSimulation()
        recognitionState = .searching
    }

    func setScanning(candidate: Landmark, progress: Double) {
        cancelSimulation()
        recognitionState = .scanning(candidate: candidate, progress: max(0, min(progress, 1)))
    }

    func setLocked(target: Landmark, confidence: Double) {
        cancelSimulation()
        recognitionState = .locked(target: target, confidence: max(0, min(confidence, 0.99)))
    }

    func playDemoSequence(candidate: Landmark? = nil) {
        cancelSimulation()
        simulationTask = Task { [weak self] in
            guard let self else { return }
            let target = candidate ?? Self.demoLandmarks.randomElement()
            guard let target else { return }

            do {
                self.recognitionState = .searching
                try await Task.sleep(for: .seconds(0.6))

                for i in 0...16 {
                    try Task.checkCancellation()
                    let progress = Double(i) / 16.0
                    self.recognitionState = .scanning(candidate: target, progress: progress)
                    try await Task.sleep(for: .milliseconds(70))
                }

                try Task.checkCancellation()
                let confidence = 0.88 + Double.random(in: 0.0...0.10)
                self.recognitionState = .locked(target: target, confidence: min(confidence, 0.99))
            } catch {
                return
            }
        }
    }

    private func cancelSimulation() {
        simulationTask?.cancel()
        simulationTask = nil
    }
}

extension HUDViewModel {
    static var demoLandmarks: [Landmark] {
        [
            Landmark(
                name: "和光本館",
                yearBuilt: "1932",
                subtitle: "銀座四丁目交差点に建つ時計塔。",
                history: "服部時計店の本店として建設され、ネオルネサンス様式の外観と時計塔は銀座のシンボルとして親しまれています。",
                distanceMeters: 150,
                bearingDegrees: 45
            ),
            Landmark(
                name: "歌舞伎座",
                yearBuilt: "2013",
                subtitle: "日本を代表する歌舞伎専用劇場。",
                history: "初代は1889年開場。現在の第五期建物は隈研吾設計で、伝統的な桃山様式と現代建築が融合しています。",
                distanceMeters: 320,
                bearingDegrees: 120
            ),
            Landmark(
                name: "銀座三越",
                yearBuilt: "1930",
                subtitle: "銀座を代表する老舗百貨店。",
                history: "日本初の百貨店・三越の銀座店として開業。正面玄関のライオン像は待ち合わせスポットとして有名です。",
                distanceMeters: 180,
                bearingDegrees: 350
            ),
            Landmark(
                name: "GINZA SIX",
                yearBuilt: "2017",
                subtitle: "銀座最大の複合商業施設。",
                history: "松坂屋銀座店跡地に誕生。谷口吉生設計の外観と草間彌生のアートが特徴的な銀座の新名所です。",
                distanceMeters: 280,
                bearingDegrees: 200
            )
        ]
    }
}
