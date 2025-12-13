import XCTest
@testable import ArGlass

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    var sut: OnboardingViewModel!

    override func setUp() {
        super.setUp()
        sut = OnboardingViewModel()
        UserDefaults.standard.removeObject(forKey: "selectedInterestIDs")
    }

    override func tearDown() {
        sut = nil
        UserDefaults.standard.removeObject(forKey: "selectedInterestIDs")
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_hasNoSelectedInterests() {
        XCTAssertTrue(sut.selectedInterests.isEmpty)
        XCTAssertEqual(sut.selectionCount, 0)
    }

    func testInitialState_isNotValidSelection() {
        XCTAssertFalse(sut.isValidSelection)
    }

    func testInitialState_canSelectMore() {
        XCTAssertTrue(sut.canSelectMore)
    }

    // MARK: - Selection Bounds Tests

    func testMinSelection_isThree() {
        XCTAssertEqual(OnboardingViewModel.minSelection, 3)
    }

    func testMaxSelection_isFive() {
        XCTAssertEqual(OnboardingViewModel.maxSelection, 5)
    }

    // MARK: - Toggle Interest Tests

    func testToggleInterest_addsInterestWhenNotSelected() {
        let interest = Interest.allInterests[0]

        sut.toggleInterest(interest)

        XCTAssertTrue(sut.isSelected(interest))
        XCTAssertEqual(sut.selectionCount, 1)
    }

    func testToggleInterest_removesInterestWhenSelected() {
        let interest = Interest.allInterests[0]
        sut.toggleInterest(interest)

        sut.toggleInterest(interest)

        XCTAssertFalse(sut.isSelected(interest))
        XCTAssertEqual(sut.selectionCount, 0)
    }

    func testToggleInterest_doesNotExceedMaxSelection() {
        for i in 0..<OnboardingViewModel.maxSelection {
            sut.toggleInterest(Interest.allInterests[i])
        }

        let extraInterest = Interest.allInterests[OnboardingViewModel.maxSelection]
        sut.toggleInterest(extraInterest)

        XCTAssertFalse(sut.isSelected(extraInterest))
        XCTAssertEqual(sut.selectionCount, OnboardingViewModel.maxSelection)
    }

    // MARK: - Validation Tests

    func testIsValidSelection_falseWhenBelowMinimum() {
        sut.toggleInterest(Interest.allInterests[0])
        sut.toggleInterest(Interest.allInterests[1])

        XCTAssertFalse(sut.isValidSelection)
    }

    func testIsValidSelection_trueWhenAtMinimum() {
        for i in 0..<OnboardingViewModel.minSelection {
            sut.toggleInterest(Interest.allInterests[i])
        }

        XCTAssertTrue(sut.isValidSelection)
    }

    func testIsValidSelection_trueWhenAtMaximum() {
        for i in 0..<OnboardingViewModel.maxSelection {
            sut.toggleInterest(Interest.allInterests[i])
        }

        XCTAssertTrue(sut.isValidSelection)
    }

    func testCanSelectMore_falseWhenAtMaximum() {
        for i in 0..<OnboardingViewModel.maxSelection {
            sut.toggleInterest(Interest.allInterests[i])
        }

        XCTAssertFalse(sut.canSelectMore)
    }

    // MARK: - Persistence Tests

    func testSaveAndLoadSelectedInterests() {
        let interest1 = Interest.allInterests[0]
        let interest2 = Interest.allInterests[1]
        let interest3 = Interest.allInterests[2]

        sut.toggleInterest(interest1)
        sut.toggleInterest(interest2)
        sut.toggleInterest(interest3)
        sut.saveSelectedInterests()

        let newViewModel = OnboardingViewModel()
        newViewModel.loadSelectedInterests()

        XCTAssertEqual(newViewModel.selectionCount, 3)
        XCTAssertTrue(newViewModel.isSelected(interest1))
        XCTAssertTrue(newViewModel.isSelected(interest2))
        XCTAssertTrue(newViewModel.isSelected(interest3))
    }

    func testGetSelectedInterests_returnsPersistedInterests() {
        let interest1 = Interest.allInterests[0]
        let interest2 = Interest.allInterests[1]
        let interest3 = Interest.allInterests[2]

        sut.toggleInterest(interest1)
        sut.toggleInterest(interest2)
        sut.toggleInterest(interest3)
        sut.saveSelectedInterests()

        let retrieved = OnboardingViewModel.getSelectedInterests()

        XCTAssertEqual(retrieved.count, 3)
        XCTAssertTrue(retrieved.contains(interest1))
    }
}
