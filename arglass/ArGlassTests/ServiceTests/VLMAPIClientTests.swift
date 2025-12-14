import XCTest
@testable import ArGlass

final class VLMAPIClientTests: XCTestCase {

    // MARK: - VLMResponse Decoding Tests

    func testVLMResponse_decodesSuccessResponse() throws {
        let json = """
        {
            "generated_text": "Tokyo Tower is an iconic landmark",
            "success": true,
            "error_message": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.generatedText, "Tokyo Tower is an iconic landmark")
        XCTAssertTrue(response.success)
        XCTAssertNil(response.errorMessage)
    }

    func testVLMResponse_decodesErrorResponse() throws {
        let json = """
        {
            "generated_text": "",
            "success": false,
            "error_message": "Model unavailable"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.generatedText, "")
        XCTAssertFalse(response.success)
        XCTAssertEqual(response.errorMessage, "Model unavailable")
    }

    func testVLMResponse_decodesWithMissingErrorMessage() throws {
        let json = """
        {
            "generated_text": "Some text",
            "success": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(VLMResponse.self, from: json)

        XCTAssertEqual(response.generatedText, "Some text")
        XCTAssertTrue(response.success)
        XCTAssertNil(response.errorMessage)
    }

    // MARK: - LandmarkAPIResponse JSON Decoding Tests

    func testLandmarkAPIResponse_decodesValidJSON() throws {
        let json = """
        {
            "name": "Tokyo Tower",
            "year_built": "1958",
            "subtitle": "Iconic communications tower",
            "history": "Built in 1958, Tokyo Tower is a communications tower in Tokyo."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LandmarkAPIResponse.self, from: json)

        XCTAssertEqual(response.name, "Tokyo Tower")
        XCTAssertEqual(response.yearBuilt, "1958")
        XCTAssertEqual(response.subtitle, "Iconic communications tower")
        XCTAssertEqual(response.history, "Built in 1958, Tokyo Tower is a communications tower in Tokyo.")
    }

    func testLandmarkAPIResponse_decodesJSON_withMissingOptionalFields() throws {
        let json = """
        {
            "name": "Test Landmark"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LandmarkAPIResponse.self, from: json)

        XCTAssertEqual(response.name, "Test Landmark")
        XCTAssertEqual(response.yearBuilt, "不明")
        XCTAssertEqual(response.subtitle, "")
        XCTAssertEqual(response.history, "")
    }

    func testLandmarkAPIResponse_decodesJSON_withIntegerYearBuilt() throws {
        let json = """
        {
            "name": "Test Landmark",
            "year_built": 1958,
            "subtitle": "",
            "history": ""
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LandmarkAPIResponse.self, from: json)

        XCTAssertEqual(response.yearBuilt, "1958")
    }

    func testLandmarkAPIResponse_decodesJSON_withDoubleYearBuilt() throws {
        let json = """
        {
            "name": "Test Landmark",
            "year_built": 1958.0,
            "subtitle": "",
            "history": ""
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LandmarkAPIResponse.self, from: json)

        XCTAssertEqual(response.yearBuilt, "1958")
    }

    func testLandmarkAPIResponse_handlesNullValues() throws {
        let json = """
        {
            "name": null,
            "year_built": null,
            "subtitle": null,
            "history": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LandmarkAPIResponse.self, from: json)

        XCTAssertEqual(response.name, "不明")
        XCTAssertEqual(response.yearBuilt, "不明")
        XCTAssertEqual(response.subtitle, "")
        XCTAssertEqual(response.history, "")
    }

    func testLandmarkAPIResponse_decodesEmptyJSON() throws {
        let json = "{}".data(using: .utf8)!

        let response = try JSONDecoder().decode(LandmarkAPIResponse.self, from: json)

        XCTAssertEqual(response.name, "不明")
        XCTAssertEqual(response.yearBuilt, "不明")
        XCTAssertEqual(response.subtitle, "")
        XCTAssertEqual(response.history, "")
    }

    // MARK: - LandmarkAPIResponse Plain Text Initialization Tests

    func testLandmarkAPIResponse_plainTextInit_extractsShortTitle() {
        let text = "Tokyo Tower is an iconic landmark."

        let response = LandmarkAPIResponse(plainText: text)

        XCTAssertEqual(response.name, "Tokyo Tower is an iconic landmark")
        XCTAssertEqual(response.yearBuilt, "—")
        XCTAssertEqual(response.subtitle, "")
        XCTAssertEqual(response.history, text)
    }

    func testLandmarkAPIResponse_plainTextInit_truncatesLongTitle() {
        let longText = "This is a very long sentence that exceeds sixty characters and should be truncated with an ellipsis."

        let response = LandmarkAPIResponse(plainText: longText)

        XCTAssertTrue(response.name.count <= 60)
        XCTAssertTrue(response.name.hasSuffix("..."))
        XCTAssertEqual(response.history, longText)
    }

    func testLandmarkAPIResponse_plainTextInit_handlesMultipleSentences() {
        let text = "Tokyo Tower is famous. It was built in 1958. It is very tall."

        let response = LandmarkAPIResponse(plainText: text)

        XCTAssertEqual(response.name, "Tokyo Tower is famous")
    }

    func testLandmarkAPIResponse_plainTextInit_handlesJapanesePeriod() {
        let text = "東京タワーは有名です。1958年に建てられました。"

        let response = LandmarkAPIResponse(plainText: text)

        XCTAssertEqual(response.name, "東京タワーは有名です")
    }

    func testLandmarkAPIResponse_plainTextInit_handlesEmptyText() {
        let response = LandmarkAPIResponse(plainText: "")

        XCTAssertEqual(response.name, "")
        XCTAssertEqual(response.history, "")
    }

    func testLandmarkAPIResponse_plainTextInit_trimsWhitespace() {
        let text = "   Tokyo Tower   "

        let response = LandmarkAPIResponse(plainText: text)

        XCTAssertEqual(response.name, "Tokyo Tower")
    }

    func testLandmarkAPIResponse_plainTextInit_handlesNewlines() {
        let text = "\nTokyo Tower is famous.\nIt was built in 1958.\n"

        let response = LandmarkAPIResponse(plainText: text)

        XCTAssertEqual(response.name, "Tokyo Tower is famous")
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
