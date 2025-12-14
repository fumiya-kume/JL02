import XCTest
@testable import ArGlass

final class CaptureOrientationTests: XCTestCase {

    func testDisplayRotationDegrees_landscapeRight_returnsZero() {
        XCTAssertEqual(CaptureOrientation.landscapeRight.displayRotationDegrees, 0)
    }

    func testDisplayRotationDegrees_landscapeLeft_returns180() {
        XCTAssertEqual(CaptureOrientation.landscapeLeft.displayRotationDegrees, 180)
    }

    func testCodable_encodeDecode_landscapeRight() throws {
        let original = CaptureOrientation.landscapeRight
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CaptureOrientation.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testCodable_encodeDecode_landscapeLeft() throws {
        let original = CaptureOrientation.landscapeLeft
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CaptureOrientation.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testRawValue_landscapeRight() {
        XCTAssertEqual(CaptureOrientation.landscapeRight.rawValue, "landscapeRight")
    }

    func testRawValue_landscapeLeft() {
        XCTAssertEqual(CaptureOrientation.landscapeLeft.rawValue, "landscapeLeft")
    }
}
