import Foundation
import SwiftUI

@MainActor
final class HUDViewModel: ObservableObject {
    enum RecognitionState: Equatable {
        case searching
        case scanning(candidate: Landmark, progress: Double)
        case locked(target: Landmark, confidence: Double)
    }

    @Published var recognitionState: RecognitionState = .searching
    @Published var isConnected: Bool = true

    let cameraService = CameraService()

    private var startupTask: Task<Void, Never>?
    private var simulationTask: Task<Void, Never>?

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
        startupTask = nil
        simulationTask = nil
        cameraService.stop()
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
                name: "東京タワー",
                yearBuilt: "1958",
                subtitle: "戦後復興の象徴として建設された電波塔。",
                history: "エッフェル塔に着想を得た設計で、昭和の東京を代表するランドマークとして親しまれています。",
                distanceMeters: 240,
                bearingDegrees: 32
            ),
            Landmark(
                name: "浅草寺",
                yearBuilt: "628",
                subtitle: "都内最古級の寺院。雷門と仲見世が有名。",
                history: "江戸期から庶民文化の中心として栄え、現在も国内外から多くの参拝者が訪れます。",
                distanceMeters: 410,
                bearingDegrees: 78
            ),
            Landmark(
                name: "国会議事堂",
                yearBuilt: "1936",
                subtitle: "日本の立法府を象徴する建築。",
                history: "石造の重厚な意匠が特徴で、近代国家の制度整備を背景に完成しました。",
                distanceMeters: 520,
                bearingDegrees: 350
            ),
            Landmark(
                name: "横浜赤レンガ倉庫",
                yearBuilt: "1911",
                subtitle: "港町の歴史を残すレンガ造の倉庫群。",
                history: "物流拠点として活躍した後、文化・商業施設として再生され、海沿いの散策地として人気です。",
                distanceMeters: 680,
                bearingDegrees: 120
            )
        ]
    }
}
