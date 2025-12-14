import XCTest
@testable import ArGlass

final class VLMAPIClientTests: XCTestCase {

    // MARK: - VLMResponse Decoding Tests

    func testVLMResponse_decodesSuccessResponse() throws {
        let json = """
        {
            "name": "Tokyo Tower",
            "facility_description": "Tokyo Tower is an iconic landmark",
            "success": true,
            "error_message": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.name, "Tokyo Tower")
        XCTAssertEqual(response.facilityDescription, "Tokyo Tower is an iconic landmark")
        XCTAssertTrue(response.success)
        XCTAssertNil(response.errorMessage)
    }

    func testVLMResponse_decodesErrorResponse() throws {
        let json = """
        {
            "name": "",
            "facility_description": "",
            "success": false,
            "error_message": "Model unavailable"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.name, "")
        XCTAssertEqual(response.facilityDescription, "")
        XCTAssertFalse(response.success)
        XCTAssertEqual(response.errorMessage, "Model unavailable")
    }

    func testVLMResponse_decodesWithMissingErrorMessage() throws {
        let json = """
        {
            "name": "Test Landmark",
            "facility_description": "Some description",
            "success": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.name, "Test Landmark")
        XCTAssertEqual(response.facilityDescription, "Some description")
        XCTAssertTrue(response.success)
        XCTAssertNil(response.errorMessage)
    }

    func testVLMResponse_decodesWithLongDescription() throws {
        let longDescription = String(repeating: "Tokyo Tower is an iconic landmark. ", count: 100)
        let json = """
        {
            "name": "Tokyo Tower",
            "facility_description": "\(longDescription)",
            "success": true,
            "error_message": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.name, "Tokyo Tower")
        XCTAssertEqual(response.facilityDescription, longDescription)
        XCTAssertTrue(response.success)
    }

    func testVLMResponse_decodesWithJapaneseContent() throws {
        let json = """
        {
            "name": "東京タワー",
            "facility_description": "東京タワーは1958年に建てられた通信塔です。",
            "success": true,
            "error_message": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.name, "東京タワー")
        XCTAssertEqual(response.facilityDescription, "東京タワーは1958年に建てられた通信塔です。")
        XCTAssertTrue(response.success)
    }

    // MARK: - VLMError Tests

    func testVLMError_imageConversionFailed_description() {
        let error = VLMError.imageConversionFailed
        XCTAssertEqual(error.errorDescription, "Failed to convert image to JPEG")
    }

    func testVLMError_invalidResponse_description() {
        let error = VLMError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid response from server")
    }

    func testVLMError_httpError_description() {
        let error = VLMError.httpError(statusCode: 500)
        XCTAssertEqual(error.errorDescription, "HTTP error: 500")
    }

    func testVLMError_apiError_description() {
        let error = VLMError.apiError(message: "Model unavailable")
        XCTAssertEqual(error.errorDescription, "API error: Model unavailable")
    }

    func testVLMError_parsingFailed_description() {
        let error = VLMError.parsingFailed
        XCTAssertEqual(error.errorDescription, "Failed to parse landmark data from response")
    }
}
