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

    // MARK: - Validation Message Tests

    func testValidationMessage_whenNoSelection_containsMinimumCount() {
        XCTAssertTrue(sut.validationMessage.contains("3"))
        XCTAssertEqual(sut.selectionCount, 0)
    }

    func testValidationMessage_whenOneSelected_showsRemainingCount() {
        sut.toggleInterest(Interest.allInterests[0])

        XCTAssertTrue(sut.validationMessage.contains("2"))
        XCTAssertEqual(sut.selectionCount, 1)
    }

    func testValidationMessage_whenTwoSelected_showsRemainingCount() {
        sut.toggleInterest(Interest.allInterests[0])
        sut.toggleInterest(Interest.allInterests[1])

        XCTAssertTrue(sut.validationMessage.contains("1"))
        XCTAssertEqual(sut.selectionCount, 2)
    }

    func testValidationMessage_whenThreeSelected_showsSelectedCount() {
        for i in 0..<3 {
            sut.toggleInterest(Interest.allInterests[i])
        }

        XCTAssertTrue(sut.validationMessage.contains("3"))
        XCTAssertTrue(sut.isValidSelection)
    }

    func testValidationMessage_whenFourSelected_showsSelectedCount() {
        for i in 0..<4 {
            sut.toggleInterest(Interest.allInterests[i])
        }

        XCTAssertTrue(sut.validationMessage.contains("4"))
        XCTAssertTrue(sut.isValidSelection)
    }

    func testValidationMessage_whenFiveSelected_showsSelectedCount() {
        for i in 0..<5 {
            sut.toggleInterest(Interest.allInterests[i])
        }

        XCTAssertTrue(sut.validationMessage.contains("5"))
        XCTAssertTrue(sut.isValidSelection)
        XCTAssertFalse(sut.canSelectMore)
    }

    // MARK: - isSelected Tests

    func testIsSelected_returnsFalseForUnselectedInterest() {
        let interest = Interest.allInterests[0]

        XCTAssertFalse(sut.isSelected(interest))
    }

    func testIsSelected_returnsTrueForSelectedInterest() {
        let interest = Interest.allInterests[0]
        sut.toggleInterest(interest)

        XCTAssertTrue(sut.isSelected(interest))
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
        XCTAssertTrue(retrieved.contains(interest2))
        XCTAssertTrue(retrieved.contains(interest3))
    }

    func testLoadSelectedInterests_whenNoSavedData_keepsEmptySelection() {
        sut.loadSelectedInterests()

        XCTAssertTrue(sut.selectedInterests.isEmpty)
        XCTAssertEqual(sut.selectionCount, 0)
    }

    func testGetSelectedInterests_whenNoSavedData_returnsEmptySet() {
        let result = OnboardingViewModel.getSelectedInterests()

        XCTAssertTrue(result.isEmpty)
    }

    func testLoadSelectedInterests_withInvalidIDs_onlyLoadsValidInterests() {
        let validID = Interest.allInterests[0].id
        let invalidID = "non_existent_interest_id"
        UserDefaults.standard.set([validID, invalidID], forKey: "selectedInterestIDs")

        sut.loadSelectedInterests()

        XCTAssertEqual(sut.selectionCount, 1)
        XCTAssertTrue(sut.isSelected(Interest.allInterests[0]))
    }

    // MARK: - Toggle Edge Case Tests

    func testToggleInterest_canRemoveAndAddDifferentInterestWhenAtMax() {
        for i in 0..<OnboardingViewModel.maxSelection {
            sut.toggleInterest(Interest.allInterests[i])
        }
        XCTAssertFalse(sut.canSelectMore)

        let removed = Interest.allInterests[0]
        sut.toggleInterest(removed)
        XCTAssertTrue(sut.canSelectMore)
        XCTAssertFalse(sut.isSelected(removed))

        let newInterest = Interest.allInterests[OnboardingViewModel.maxSelection]
        sut.toggleInterest(newInterest)
        XCTAssertTrue(sut.isSelected(newInterest))
        XCTAssertEqual(sut.selectionCount, OnboardingViewModel.maxSelection)
    }

    func testToggleInterest_multipleTimes_togglesCorrectly() {
        let interest = Interest.allInterests[0]

        sut.toggleInterest(interest)
        XCTAssertTrue(sut.isSelected(interest))

        sut.toggleInterest(interest)
        XCTAssertFalse(sut.isSelected(interest))

        sut.toggleInterest(interest)
        XCTAssertTrue(sut.isSelected(interest))

        sut.toggleInterest(interest)
        XCTAssertFalse(sut.isSelected(interest))
    }
}
