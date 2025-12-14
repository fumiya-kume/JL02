import XCTest
@testable import ArGlass

@MainActor
final class HistoryViewModelTests: XCTestCase {

    var sut: HistoryViewModel!
    var mockHistoryService: MockHistoryService!

    override func setUp() async throws {
        try await super.setUp()
        mockHistoryService = MockHistoryService()
        sut = HistoryViewModel(historyService: mockHistoryService)
    }

    override func tearDown() async throws {
        sut = nil
        mockHistoryService = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_entriesIsEmpty() {
        XCTAssertTrue(sut.entries.isEmpty)
    }

    func testInitialState_isEmptyReturnsTrue() {
        XCTAssertTrue(sut.isEmpty)
    }

    func testInitialState_expandedEntryIDIsNil() {
        XCTAssertNil(sut.expandedEntryID)
    }

    func testInitialState_showingClearConfirmationIsFalse() {
        XCTAssertFalse(sut.showingClearConfirmation)
    }

    // MARK: - Toggle Expanded Tests

    func testToggleExpanded_setsExpandedEntryID() {
        let entry = TestFixtures.makeHistoryEntry()

        sut.toggleExpanded(entry)

        XCTAssertEqual(sut.expandedEntryID, entry.id)
    }

    func testToggleExpanded_togglesOffWhenSameEntry() {
        let entry = TestFixtures.makeHistoryEntry()

        sut.toggleExpanded(entry)
        sut.toggleExpanded(entry)

        XCTAssertNil(sut.expandedEntryID)
    }

    func testToggleExpanded_switchesToDifferentEntry() {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")

        sut.toggleExpanded(entry1)
        sut.toggleExpanded(entry2)

        XCTAssertEqual(sut.expandedEntryID, entry2.id)
    }

    // MARK: - isExpanded Tests

    func testIsExpanded_returnsTrueForExpandedEntry() {
        let entry = TestFixtures.makeHistoryEntry()
        sut.toggleExpanded(entry)

        XCTAssertTrue(sut.isExpanded(entry))
    }

    func testIsExpanded_returnsFalseForCollapsedEntry() {
        let entry = TestFixtures.makeHistoryEntry()

        XCTAssertFalse(sut.isExpanded(entry))
    }

    // MARK: - Date Formatting Tests

    func testFormatTimestamp_returnsNonEmptyString() {
        let date = Date()
        let result = sut.formatTimestamp(date)

        XCTAssertFalse(result.isEmpty)
    }

    func testFormatDateHeader_returnsTodayForToday() {
        let today = Date()
        let result = sut.formatDateHeader(today)

        let expectedKey = NSLocalizedString("history_today", comment: "")
        XCTAssertEqual(result, expectedKey)
    }

    func testFormatDateHeader_returnsYesterdayForYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = sut.formatDateHeader(yesterday)

        let expectedKey = NSLocalizedString("history_yesterday", comment: "")
        XCTAssertEqual(result, expectedKey)
    }

    // MARK: - Grouped By Date Tests

    func testGroupedByDate_emptyWhenNoEntries() {
        XCTAssertTrue(sut.groupedByDate.isEmpty)
        XCTAssertTrue(sut.sortedDates.isEmpty)
    }
    
    // MARK: - Load History Tests
    
    func testLoadHistory_populatesEntriesFromService() async {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")
        await mockHistoryService.setEntries([entry1, entry2])
        
        await sut.loadHistory()
        
        XCTAssertEqual(sut.entries.count, 2)
        XCTAssertEqual(sut.entries[0].name, "Entry 1")
        XCTAssertEqual(sut.entries[1].name, "Entry 2")
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testLoadHistory_withEmptyService_resultsInEmptyEntries() async {
        await sut.loadHistory()
        
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testLoadHistory_populatesImageURLs() async {
        let entry = TestFixtures.makeHistoryEntry(imageFileName: "test.jpg")
        let expectedURL = URL(string: "file:///test/path/test.jpg")!
        await mockHistoryService.setEntries([entry])
        await mockHistoryService.setMockImageURL(expectedURL, for: entry.id)
        
        await sut.loadHistory()
        
        XCTAssertEqual(sut.imageURLs[entry.id], expectedURL)
    }
    
    func testLoadHistory_withNoImageFile_imageURLIsNil() async {
        let entry = TestFixtures.makeHistoryEntry(imageFileName: nil)
        await mockHistoryService.setEntries([entry])
        
        await sut.loadHistory()
        
        XCTAssertNil(sut.imageURLs[entry.id])
    }
    
    // MARK: - Delete Entry Tests
    
    func testDeleteEntry_removesFromLocalEntries() async {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")
        await mockHistoryService.setEntries([entry1, entry2])
        await sut.loadHistory()
        
        await sut.deleteEntry(entry1)
        
        XCTAssertEqual(sut.entries.count, 1)
        XCTAssertEqual(sut.entries.first?.name, "Entry 2")
    }
    
    func testDeleteEntry_callsServiceDeleteEntry() async {
        let entry = TestFixtures.makeHistoryEntry()
        await mockHistoryService.setEntries([entry])
        await sut.loadHistory()
        
        await sut.deleteEntry(entry)
        
        let callCount = await mockHistoryService.getDeleteEntryCallCount()
        XCTAssertEqual(callCount, 1)
    }
    
    func testDeleteEntry_nonExistentEntry_doesNotCrash() async {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")
        await mockHistoryService.setEntries([entry1])
        await sut.loadHistory()
        
        await sut.deleteEntry(entry2)
        
        XCTAssertEqual(sut.entries.count, 1)
    }
    
    // MARK: - Clear All Tests
    
    func testClearAll_removesAllLocalEntries() async {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")
        await mockHistoryService.setEntries([entry1, entry2])
        await sut.loadHistory()
        
        await sut.clearAll()
        
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testClearAll_callsServiceClearAll() async {
        let entry = TestFixtures.makeHistoryEntry()
        await mockHistoryService.setEntries([entry])
        await sut.loadHistory()
        
        await sut.clearAll()
        
        let callCount = await mockHistoryService.getClearAllCallCount()
        XCTAssertEqual(callCount, 1)
    }
    
    func testClearAll_onEmptyList_doesNotCrash() async {
        await sut.clearAll()
        
        XCTAssertTrue(sut.entries.isEmpty)
    }
    
    // MARK: - Image URL Tests
    
    func testImageURL_returnsURLFromService() async {
        let entry = TestFixtures.makeHistoryEntry(imageFileName: "test.jpg")
        let expectedURL = URL(string: "file:///test/path/test.jpg")!
        await mockHistoryService.setMockImageURL(expectedURL, for: entry.id)
        
        let result = await sut.imageURL(for: entry)
        
        XCTAssertEqual(result, expectedURL)
    }
    
    func testImageURL_withNoImage_returnsNil() async {
        let entry = TestFixtures.makeHistoryEntry(imageFileName: nil)
        
        let result = await sut.imageURL(for: entry)
        
        XCTAssertNil(result)
    }
    
    // MARK: - Grouped By Date Tests (Enhanced)
    
    func testGroupedByDate_groupsEntriesByDay() async {
        let calendar = Calendar.current
        let fixedDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 15, hour: 14, minute: 0))!
        let previousDay = calendar.date(byAdding: .day, value: -1, to: fixedDate)!
        
        let entry1 = TestFixtures.makeHistoryEntry(name: "Day 1", timestamp: fixedDate)
        let entry2 = TestFixtures.makeHistoryEntry(name: "Day 2", timestamp: fixedDate.addingTimeInterval(-3600))
        let entry3 = TestFixtures.makeHistoryEntry(name: "Previous Day", timestamp: previousDay)
        
        await mockHistoryService.setEntries([entry1, entry2, entry3])
        await sut.loadHistory()
        
        let grouped = sut.groupedByDate
        XCTAssertEqual(grouped.count, 2)
        
        let day1Key = calendar.startOfDay(for: fixedDate)
        let day2Key = calendar.startOfDay(for: previousDay)
        
        let day1Count = grouped[day1Key]?.count ?? 0
        let day2Count = grouped[day2Key]?.count ?? 0
        
        XCTAssertEqual(day1Count, 2, "Should have 2 entries for day 1")
        XCTAssertEqual(day2Count, 1, "Should have 1 entry for previous day")
    }
    
    func testSortedDates_returnsNewestFirst() async {
        let calendar = Calendar.current
        let fixedDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 15, hour: 14, minute: 0))!
        let day1 = calendar.startOfDay(for: fixedDate)
        let day2 = calendar.date(byAdding: .day, value: -1, to: day1)!
        let day3 = calendar.date(byAdding: .day, value: -2, to: day1)!
        
        let entry1 = TestFixtures.makeHistoryEntry(timestamp: day3.addingTimeInterval(10 * 3600))
        let entry2 = TestFixtures.makeHistoryEntry(timestamp: day1.addingTimeInterval(10 * 3600))
        let entry3 = TestFixtures.makeHistoryEntry(timestamp: day2.addingTimeInterval(10 * 3600))
        
        await mockHistoryService.setEntries([entry1, entry2, entry3])
        await sut.loadHistory()
        
        let sortedDates = sut.sortedDates
        XCTAssertEqual(sortedDates.count, 3)
        XCTAssertEqual(sortedDates[0], day1)
        XCTAssertEqual(sortedDates[1], day2)
        XCTAssertEqual(sortedDates[2], day3)
    }
    
    func testGroupedByDate_sameDay_groupedTogether() async {
        let baseDate = Date()
        let morning = Calendar.current.startOfDay(for: baseDate).addingTimeInterval(9 * 3600)
        let evening = Calendar.current.startOfDay(for: baseDate).addingTimeInterval(18 * 3600)
        
        let entry1 = TestFixtures.makeHistoryEntry(name: "Morning", timestamp: morning)
        let entry2 = TestFixtures.makeHistoryEntry(name: "Evening", timestamp: evening)
        
        await mockHistoryService.setEntries([entry1, entry2])
        await sut.loadHistory()
        
        let grouped = sut.groupedByDate
        XCTAssertEqual(grouped.count, 1)
        
        let dayKey = Calendar.current.startOfDay(for: baseDate)
        XCTAssertEqual(grouped[dayKey]?.count, 2)
    }
    
    func testSortedDates_withSingleEntry_returnsOneDate() async {
        let entry = TestFixtures.makeHistoryEntry()
        await mockHistoryService.setEntries([entry])
        await sut.loadHistory()
        
        XCTAssertEqual(sut.sortedDates.count, 1)
    }
    
    // MARK: - Date Formatting Tests (Enhanced)
    
    func testFormatDateHeader_twoDaysAgo_returnsFormattedDate() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        let result = sut.formatDateHeader(twoDaysAgo)
        
        let todayKey = NSLocalizedString("history_today", comment: "")
        let yesterdayKey = NSLocalizedString("history_yesterday", comment: "")
        XCTAssertNotEqual(result, todayKey)
        XCTAssertNotEqual(result, yesterdayKey)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testFormatDateHeader_lastWeek_returnsFormattedDate() {
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        let result = sut.formatDateHeader(lastWeek)
        
        let todayKey = NSLocalizedString("history_today", comment: "")
        let yesterdayKey = NSLocalizedString("history_yesterday", comment: "")
        XCTAssertNotEqual(result, todayKey)
        XCTAssertNotEqual(result, yesterdayKey)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testFormatDateHeader_lastMonth_returnsFormattedDate() {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        
        let result = sut.formatDateHeader(lastMonth)
        
        let todayKey = NSLocalizedString("history_today", comment: "")
        let yesterdayKey = NSLocalizedString("history_yesterday", comment: "")
        XCTAssertNotEqual(result, todayKey)
        XCTAssertNotEqual(result, yesterdayKey)
        XCTAssertFalse(result.isEmpty)
    }
    
    // MARK: - Edge Case Tests
    
    func testToggleExpanded_afterLoadHistory_worksCorrectly() async {
        let entry = TestFixtures.makeHistoryEntry()
        await mockHistoryService.setEntries([entry])
        await sut.loadHistory()
        
        sut.toggleExpanded(sut.entries.first!)
        
        XCTAssertTrue(sut.isExpanded(sut.entries.first!))
    }
    
    func testDeleteEntry_preservesOtherEntries() async {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")
        let entry3 = TestFixtures.makeHistoryEntry(name: "Entry 3")
        await mockHistoryService.setEntries([entry1, entry2, entry3])
        await sut.loadHistory()
        
        await sut.deleteEntry(entry2)
        
        XCTAssertEqual(sut.entries.count, 2)
        XCTAssertTrue(sut.entries.contains { $0.name == "Entry 1" })
        XCTAssertTrue(sut.entries.contains { $0.name == "Entry 3" })
        XCTAssertFalse(sut.entries.contains { $0.name == "Entry 2" })
    }
    
    func testLoadHistory_multipleLoads_replacesEntries() async {
        let entry1 = TestFixtures.makeHistoryEntry(name: "First Load")
        await mockHistoryService.setEntries([entry1])
        await sut.loadHistory()
        XCTAssertEqual(sut.entries.count, 1)
        
        let entry2 = TestFixtures.makeHistoryEntry(name: "Second Load")
        await mockHistoryService.setEntries([entry2])
        await sut.loadHistory()
        
        XCTAssertEqual(sut.entries.count, 1)
        XCTAssertEqual(sut.entries.first?.name, "Second Load")
    }
}
