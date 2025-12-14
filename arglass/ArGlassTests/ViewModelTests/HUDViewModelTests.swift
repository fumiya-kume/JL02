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
        await mockHistoryService.addEntry(HistoryEntry(name: "", description: ""), image: nil)
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

    // MARK: - Retry Logic Tests

    func testPerformInference_failure_returnsConsecutiveFalse() async {
        // Setup
        mockCameraService.mockFrame = UIImage(systemName: "camera")
        await mockVLMClient.setShouldFailInference(true)

        // Execute
        let result1 = await sut.performInference()
        let result2 = await sut.performInference()

        // Assert
        XCTAssertFalse(result1)
        XCTAssertFalse(result2)
        XCTAssertEqual(sut.apiRequestState, .error(message: "API error: Mock error"))
    }

    func testPerformInference_successAfterFailure_resetsState() async {
        // Setup
        let testImage = UIImage(systemName: "camera")!
        mockCameraService.mockFrame = testImage
        await mockVLMClient.setShouldFailInference(true)

        // First call fails
        let failResult = await sut.performInference()
        XCTAssertFalse(failResult)

        // Configure success
        await mockVLMClient.setShouldFailInference(false)
        await mockVLMClient.setMockLandmark(TestFixtures.makeLandmark())

        // Second call succeeds
        let successResult = await sut.performInference()

        // Assert
        XCTAssertTrue(successResult)
        if case .success = sut.apiRequestState { } else {
            XCTFail("Expected success state but got \(sut.apiRequestState)")
        }
    }

    func testPerformInference_multipleConsecutiveFailures_allReturnFalse() async {
        // Setup
        mockCameraService.mockFrame = UIImage(systemName: "camera")
        await mockVLMClient.setShouldFailInference(true)

        // Execute
        var results: [Bool] = []
        for _ in 0..<4 {
            results.append(await sut.performInference())
        }

        // Assert
        XCTAssertEqual(results, [false, false, false, false])
        XCTAssertEqual(sut.apiRequestState, .error(message: "API error: Mock error"))
    }

    // MARK: - Stop Auto Inference Camera State Tests

    func testStopAutoInference_whenCameraPreviewEnabled_keepsCameraRunning() async {
        // Setup
        sut.isCameraPreviewEnabled = true
        sut.startAutoInference()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Execute
        sut.stopAutoInference()

        // Assert
        XCTAssertFalse(sut.isAutoInferenceEnabled)
        XCTAssertEqual(mockCameraService.state, .running)
    }

    func testStopAutoInference_whenCameraPreviewDisabled_stopsCamera() async {
        // Setup
        sut.startAutoInference()
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.isCameraPreviewEnabled = false

        // Execute
        sut.stopAutoInference()

        // Assert
        XCTAssertFalse(sut.isAutoInferenceEnabled)
        XCTAssertEqual(mockCameraService.state, .idle)
    }

    // MARK: - Toggle Camera Preview Logic Tests

    func testToggleCameraPreview_enablePreview_startsCamera() async {
        // Setup
        sut.isCameraPreviewEnabled = false
        mockCameraService.stop()

        // Execute
        sut.toggleCameraPreview()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertTrue(sut.isCameraPreviewEnabled)
        XCTAssertEqual(mockCameraService.state, .running)
    }

    func testToggleCameraPreview_disableWithAutoInferenceRunning_keepsCameraRunning() async {
        // Setup
        sut.isCameraPreviewEnabled = true
        sut.startAutoInference()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockCameraService.state, .running)

        // Execute
        sut.toggleCameraPreview()

        // Assert
        XCTAssertFalse(sut.isCameraPreviewEnabled)
        XCTAssertTrue(sut.isAutoInferenceEnabled)
        XCTAssertEqual(mockCameraService.state, .running)
    }

    func testToggleCameraPreview_disableWithNoAutoInference_stopsCamera() async {
        // Setup
        sut.isCameraPreviewEnabled = true
        await mockCameraService.requestAccessAndStart()
        XCTAssertFalse(sut.isAutoInferenceEnabled)

        // Execute
        sut.toggleCameraPreview()

        // Assert
        XCTAssertFalse(sut.isCameraPreviewEnabled)
        XCTAssertFalse(sut.isAutoInferenceEnabled)
        XCTAssertEqual(mockCameraService.state, .idle)
    }
}
