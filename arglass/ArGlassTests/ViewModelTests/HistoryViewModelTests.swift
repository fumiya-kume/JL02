import XCTest
@testable import ArGlass

@MainActor
final class HistoryViewModelTests: XCTestCase {

    var sut: HistoryViewModel!

    override func setUp() {
        super.setUp()
        sut = HistoryViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
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
}
