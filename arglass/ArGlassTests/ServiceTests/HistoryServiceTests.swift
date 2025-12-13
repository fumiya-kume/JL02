import XCTest
@testable import ArGlass

final class HistoryServiceTests: XCTestCase {
    private var historyService: HistoryService!
    private var tempDirectory: URL!
    
    override func setUp() async throws {
        // Create a temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        
        // Create a HistoryService instance that uses the temp directory
        historyService = HistoryService(
            fileURL: tempDirectory.appendingPathComponent("history.json"),
            imageDirectoryURL: tempDirectory.appendingPathComponent("images")
        )
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectory)
        historyService = nil
        tempDirectory = nil
    }
    
    // MARK: - Load History Tests
    
    func testLoadHistory_whenNoFile_returnsEmptyArray() async {
        let history = await historyService.loadHistory()
        XCTAssertTrue(history.isEmpty)
    }
    
    func testLoadHistory_whenFileExists_returnsEntries() async {
        // Create test data
        let entry1 = TestFixtures.makeHistoryEntry(name: "Landmark 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Landmark 2")
        
        // Save entries
        await historyService.addEntry(entry1, image: nil)
        await historyService.addEntry(entry2, image: nil)
        
        // Load history
        let history = await historyService.loadHistory()
        
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].name, entry2.name) // Should be in reverse order (newest first)
        XCTAssertEqual(history[1].name, entry1.name)
    }
    
    // MARK: - Add Entry Tests
    
    func testAddEntry_savesEntry() async {
        let entry = TestFixtures.makeHistoryEntry(name: "Test Landmark")
        
        await historyService.addEntry(entry, image: nil)
        
        let history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].name, entry.name)
    }
    
    func testAddEntry_withImage_savesImage() async {
        let entry = TestFixtures.makeHistoryEntry(name: "Test Landmark")
        let testImage = UIImage(systemName: "camera")!
        
        await historyService.addEntry(entry, image: testImage)
        
        let history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertNotNil(history[0].imageFileName)
        
        // Verify image file exists
        let imageURL = await historyService.imageURL(for: history[0])
        XCTAssertNotNil(imageURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL!.path))
    }
    
    func testAddEntry_whenDuplicateWithinThreshold_doesNotAdd() async {
        let entry = TestFixtures.makeHistoryEntry(name: "Test Landmark")
        
        // Add entry twice
        await historyService.addEntry(entry, image: nil)
        await historyService.addEntry(entry, image: nil)
        
        let history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 1, "Should not add duplicate within threshold")
    }
    
    func testAddEntry_whenOlderThanThreshold_addsDuplicate() async {
        let entry1 = TestFixtures.makeHistoryEntry(
            name: "Test Landmark",
            timestamp: Date().addingTimeInterval(-400) // 400 seconds ago (beyond 300s threshold)
        )
        let entry2 = TestFixtures.makeHistoryEntry(
            name: "Test Landmark",
            timestamp: Date()
        )
        
        await historyService.addEntry(entry1, image: nil)
        await historyService.addEntry(entry2, image: nil)
        
        let history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 2, "Should add duplicate when older than threshold")
    }
    
    func testAddEntry_whenExceedsMaxEntries_removesOldest() async {
        // Add max entries + 1
        for i in 0..<51 {
            let entry = TestFixtures.makeHistoryEntry(name: "Landmark \(i)")
            await historyService.addEntry(entry, image: nil)
        }
        
        let history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 50, "Should maintain maximum of 50 entries")
        XCTAssertEqual(history.last?.name, "Landmark 1", "Oldest entry (after the first one) should be removed")
        XCTAssertEqual(history.first?.name, "Landmark 50", "Newest entry should be at front")
    }
    
    // MARK: - Delete Entry Tests
    
    func testDeleteEntry_removesEntryAndImage() async {
        let entry = TestFixtures.makeHistoryEntry(name: "Test Landmark")
        let testImage = UIImage(systemName: "camera")!
        
        await historyService.addEntry(entry, image: testImage)
        
        // Verify entry and image exist
        var history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 1)
        var imageURL = await historyService.imageURL(for: history[0])
        XCTAssertNotNil(imageURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL!.path))
        
        // Delete entry
        await historyService.deleteEntry(history[0])
        
        // Verify entry and image are deleted
        history = await historyService.loadHistory()
        XCTAssertTrue(history.isEmpty)
        imageURL = await historyService.imageURL(for: entry)
        XCTAssertNil(imageURL)
    }
    
    // MARK: - Clear All Tests
    
    func testClearAll_removesAllEntriesAndImages() async {
        // Add multiple entries with images
        for i in 0..<5 {
            let entry = TestFixtures.makeHistoryEntry(name: "Landmark \(i)")
            let testImage = UIImage(systemName: "camera")!
            await historyService.addEntry(entry, image: testImage)
        }
        
        // Verify entries exist
        var history = await historyService.loadHistory()
        XCTAssertEqual(history.count, 5)
        
        // Clear all
        await historyService.clearAll()
        
        // Verify everything is deleted
        history = await historyService.loadHistory()
        XCTAssertTrue(history.isEmpty)
        
        // Check that image directory is empty
        let imageFiles = try? FileManager.default.contentsOfDirectory(
            at: tempDirectory.appendingPathComponent("images"),
            includingPropertiesForKeys: nil
        )
        XCTAssertEqual(imageFiles?.count, 0)
    }
    
    // MARK: - Image URL Tests
    
    func testImageURL_whenImageExists_returnsURL() async {
        let entry = TestFixtures.makeHistoryEntry(name: "Test Landmark")
        let testImage = UIImage(systemName: "camera")!
        
        await historyService.addEntry(entry, image: testImage)
        
        let history = await historyService.loadHistory()
        let imageURL = await historyService.imageURL(for: history[0])
        
        XCTAssertNotNil(imageURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL!.path))
    }
    
    func testImageURL_whenNoImage_returnsNil() async {
        let entry = TestFixtures.makeHistoryEntry(name: "Test Landmark")
        
        await historyService.addEntry(entry, image: nil)
        
        let history = await historyService.loadHistory()
        let imageURL = await historyService.imageURL(for: history[0])
        
        XCTAssertNil(imageURL)
    }
    
    func testImageURL_whenImageFileMissing_returnsNil() async {
        let entry = TestFixtures.makeHistoryEntry(
            name: "Test Landmark",
            imageFileName: "nonexistent.jpg"
        )
        
        let imageURL = await historyService.imageURL(for: entry)
        XCTAssertNil(imageURL)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadHistory_withCorruptedJSON_returnsEmptyArray() async {
        // Write invalid JSON to file
        let invalidJSON = "{ invalid json".data(using: .utf8)!
        do {
            try invalidJSON.write(
                to: tempDirectory.appendingPathComponent("history.json"),
                options: .atomic
            )
        } catch {
            XCTFail("Failed to write invalid JSON: \(error)")
        }
        
        let history = await historyService.loadHistory()
        XCTAssertTrue(history.isEmpty, "Should return empty array for corrupted JSON")
    }
}
