import XCTest
@testable import ArGlass

@MainActor
final class HUDViewModelTests: XCTestCase {
    
    var sut: HUDViewModel!
    var mockCameraService: MockCameraService!
    var mockLocationService: MockLocationService!
    var mockVLMClient: MockVLMAPIClient!
    var mockHistoryService: MockHistoryService!
    
    override func setUp() async throws {
        mockCameraService = MockCameraService()
        mockLocationService = MockLocationService()
        mockVLMClient = MockVLMAPIClient()
        mockHistoryService = MockHistoryService()
        
        sut = HUDViewModel(
            cameraService: mockCameraService,
            locationService: mockLocationService,
            vlmAPIClient: mockVLMClient,
            historyService: mockHistoryService
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockCameraService = nil
        mockLocationService = nil
        mockVLMClient = nil
        mockHistoryService = nil
    }
    
    // MARK: - Helper Functions
    
    func closeTo(_ expected: Double, within tolerance: Double) -> Double {
        return expected
    }
    
    func assertEqualAPIState(_ state: HUDViewModel.APIRequestState, expectedResponseTime: Double, accuracy: Double = 0.1, file: StaticString = #filePath, line: UInt = #line) {
        if case .success(let responseTime) = state {
            XCTAssertEqual(responseTime, expectedResponseTime, accuracy: accuracy, file: file, line: line)
        } else {
            XCTFail("Expected .success state but got \(state)", file: file, line: line)
        }
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_isCorrect() {
        XCTAssertEqual(sut.recognitionState, .searching)
        XCTAssertTrue(sut.isConnected)
        XCTAssertFalse(sut.isAutoInferenceEnabled)
        XCTAssertEqual(sut.apiRequestState, .idle)
        XCTAssertEqual(sut.captureState, .idle)
        XCTAssertTrue(sut.errorMessage.isEmpty)
        XCTAssertTrue(sut.isCameraPreviewEnabled)
        XCTAssertNil(sut.lastCapturedImage)
        XCTAssertEqual(sut.cameraService.state, .idle)
        XCTAssertEqual(sut.locationService.state, .idle)
    }
    
    // MARK: - State Management Tests
    
    func testSetSearching_updatesState() {
        sut.lastCapturedImage = UIImage(systemName: "test")
        
        sut.setSearching()
        
        XCTAssertEqual(sut.recognitionState, .searching)
        XCTAssertNil(sut.lastCapturedImage)
    }
    
    func testSetScanning_updatesState() {
        let landmark = TestFixtures.makeLandmark()
        
        sut.setScanning(candidate: landmark, progress: 0.5)
        
        if case .scanning(let candidate, let progress) = sut.recognitionState {
            XCTAssertEqual(candidate.name, landmark.name)
            XCTAssertEqual(progress, 0.5)
        } else {
            XCTFail("Expected scanning state")
        }
    }
    
    func testSetScanning_clampsProgress() {
        let landmark = TestFixtures.makeLandmark()
        
        sut.setScanning(candidate: landmark, progress: -0.5)
        if case .scanning(_, let progress) = sut.recognitionState {
            XCTAssertEqual(progress, 0.0, "Progress should be clamped to minimum 0")
        }
        
        sut.setScanning(candidate: landmark, progress: 1.5)
        if case .scanning(_, let progress) = sut.recognitionState {
            XCTAssertEqual(progress, 1.0, "Progress should be clamped to maximum 1")
        }
    }
    
    func testSetLocked_updatesState() {
        let landmark = TestFixtures.makeLandmark()
        
        sut.setLocked(target: landmark, confidence: 0.95)
        
        if case .locked(let target, let confidence) = sut.recognitionState {
            XCTAssertEqual(target.name, landmark.name)
            XCTAssertEqual(confidence, 0.95)
        } else {
            XCTFail("Expected locked state")
        }
    }
    
    func testSetLocked_clampsConfidence() {
        let landmark = TestFixtures.makeLandmark()
        
        sut.setLocked(target: landmark, confidence: -0.5)
        if case .locked(_, let confidence) = sut.recognitionState {
            XCTAssertEqual(confidence, 0.0, "Confidence should be clamped to minimum 0")
        }
        
        sut.setLocked(target: landmark, confidence: 1.5)
        if case .locked(_, let confidence) = sut.recognitionState {
            XCTAssertEqual(confidence, 0.99, "Confidence should be clamped to maximum 0.99")
        }
    }
    
    // MARK: - Start/Stop Tests
    
    func testStart_startsServices() async {
        sut.start()
        
        // Wait a bit for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(mockCameraService.state, .running)
        XCTAssertEqual(mockLocationService.state, .updating)
        XCTAssertTrue(sut.isAutoInferenceEnabled)
    }
    
    func testStop_stopsServices() async {
        // First start
        await sut.start()
        sut.startAutoInference()
        
        // Then stop
        sut.stop()
        
        XCTAssertFalse(sut.isAutoInferenceEnabled)
        XCTAssertEqual(mockCameraService.state, .idle)
        XCTAssertEqual(mockLocationService.state, .authorized) // stopUpdating changes state from updating to authorized
    }
    
    // MARK: - Auto Inference Tests
    
    func testStartAutoInference_enablesInference() {
        sut.startAutoInference()
        
        XCTAssertTrue(sut.isAutoInferenceEnabled)
    }
    
    func testStartAutoInference_whenAlreadyEnabled_doesNothing() {
        sut.startAutoInference()
        
        // Try to start again
        let wasEnabled = sut.isAutoInferenceEnabled
        sut.startAutoInference()
        
        XCTAssertTrue(sut.isAutoInferenceEnabled)
        XCTAssertTrue(wasEnabled, "Should have been enabled already")
    }
    
    func testStopAutoInference_disablesInference() {
        sut.startAutoInference()
        sut.stopAutoInference()
        
        XCTAssertFalse(sut.isAutoInferenceEnabled)
    }
    
    // MARK: - Inference Success Tests
    
    func testPerformInference_success_updatesStates() async {
        // Setup
        let testImage = UIImage(systemName: "camera")!
        mockCameraService.mockFrame = testImage
        let expectedLandmark = TestFixtures.makeLandmark(name: "Test Landmark")
        await mockVLMClient.setMockLandmark(expectedLandmark)
        
        // Execute
        let result = await sut.performInference()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(sut.captureState, .captured(imageSizeKB: Double(testImage.jpegData(compressionQuality: 0.8)!.count) / 1024.0))
        assertEqualAPIState(sut.apiRequestState, expectedResponseTime: 0.0, accuracy: 1.0)
        
        if case .locked(let landmark, _) = sut.recognitionState {
            XCTAssertEqual(landmark.name, expectedLandmark.name)
        } else {
            XCTFail("Expected locked state")
        }
        
        XCTAssertEqual(sut.lastCapturedImage, testImage)
        XCTAssertTrue(sut.errorMessage.isEmpty)
        
        // Verify history was saved
        await mockHistoryService.addEntry(HistoryEntry(name: "", yearBuilt: "", subtitle: "", history: "", distanceMeters: 0, bearingDegrees: 0), image: nil)
        let callCount = await mockHistoryService.getAddEntryCallCount()
        XCTAssertEqual(callCount, 2) // One from performInference, one from our manual call
    }
    
    // MARK: - Inference Failure Tests
    
    func testPerformInference_captureFailure_updatesErrorState() async {
        mockCameraService.shouldFailCapture = true
        
        let result = await sut.performInference()
        
        XCTAssertFalse(result)
        XCTAssertEqual(sut.captureState, .failed)
        XCTAssertEqual(sut.apiRequestState, .idle)
        XCTAssertFalse(sut.errorMessage.isEmpty)
    }
    
    func testPerformInference_jpegConversionFailure_updatesErrorState() async {
        // Create a mock image that returns nil for jpegData
        mockCameraService.mockFrame = UIImage()
        
        let result = await sut.performInference()
        
        XCTAssertFalse(result)
        XCTAssertEqual(sut.captureState, .failed)
        XCTAssertEqual(sut.apiRequestState, .idle)
        XCTAssertFalse(sut.errorMessage.isEmpty)
    }
    
    func testPerformInference_apiFailure_updatesErrorState() async {
        mockCameraService.mockFrame = UIImage(systemName: "camera")
        await mockVLMClient.setShouldFailInference(true)
        
        let result = await sut.performInference()
        
        XCTAssertFalse(result)
        XCTAssertEqual(sut.apiRequestState, .error(message: "API error: Mock error"))
        XCTAssertFalse(sut.errorMessage.isEmpty)
    }
    
    // MARK: - Camera Preview Toggle Tests
    
    func testToggleCameraPreview_togglesState() {
        let initialState = sut.isCameraPreviewEnabled
        
        sut.isCameraPreviewEnabled.toggle()
        
        XCTAssertNotEqual(sut.isCameraPreviewEnabled, initialState)
    }
}
