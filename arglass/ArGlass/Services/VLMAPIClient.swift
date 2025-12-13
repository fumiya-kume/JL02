import CoreLocation
import Foundation
import UIKit

struct VLMResponse: Codable {
    let generatedText: String
    let success: Bool
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case generatedText = "generated_text"
        case success
        case errorMessage = "error_message"
    }
}

struct LandmarkAPIResponse: Codable {
    let name: String
    let yearBuilt: String
    let subtitle: String
    let history: String

    enum CodingKeys: String, CodingKey {
        case name
        case yearBuilt = "year_built"
        case subtitle
        case history
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = Self.decodeString(from: container, key: .name) ?? "不明"
        yearBuilt = Self.decodeString(from: container, key: .yearBuilt) ?? "不明"
        subtitle = Self.decodeString(from: container, key: .subtitle) ?? ""
        history = Self.decodeString(from: container, key: .history) ?? ""
    }

    private static func decodeString(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> String? {
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        return nil
    }

    init(plainText: String) {
        self.name = Self.extractTitle(from: plainText)
        self.yearBuilt = "—"
        self.subtitle = ""
        self.history = plainText
    }

    private static func extractTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let sentences = trimmed.components(separatedBy: CharacterSet(charactersIn: "。."))
        if let firstSentence = sentences.first, !firstSentence.isEmpty {
            let sentence = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count <= 60 {
                return sentence
            }
            return String(sentence.prefix(57)) + "..."
        }

        if trimmed.count <= 60 {
            return trimmed
        }
        return String(trimmed.prefix(57)) + "..."
    }
}

actor VLMAPIClient: VLMAPIClientProtocol {
    static let shared = VLMAPIClient()

    private let baseURL = URL(string: "https://app-54c362a6-dce4-4819-9c60-2ce0d0024e46.ingress.apprun.sakura.ne.jp")!
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func inferLandmark(image: UIImage, locationInfo: LocationInfo? = nil, interests: Set<Interest> = [], preferences: UserPreferences = .default) async throws -> Landmark {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            print("[VLM] ❌ Failed to convert image to JPEG")
            throw VLMError.imageConversionFailed
        }

        return try await inferLandmark(jpegData: jpegData, locationInfo: locationInfo, interests: interests, preferences: preferences)
    }

    func inferLandmark(jpegData: Data, locationInfo: LocationInfo? = nil, interests: Set<Interest> = [], preferences: UserPreferences = .default) async throws -> Landmark {
        let url = baseURL.appendingPathComponent("inference")

        print("[VLM] 🚀 Sending request to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        print("[VLM] 🖼️ Image size: \(jpegData.count) bytes (\(String(format: "%.2f", Double(jpegData.count) / 1024.0)) KB)")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpegData)
        body.append("\r\n".data(using: .utf8)!)

        let address = locationInfo?.formattedAddress ?? ""
        body.appendFormField(name: "address", value: address, boundary: boundary)

        let latitude = locationInfo?.coordinate.latitude ?? 0
        body.appendFormField(name: "latitude", value: String(latitude), boundary: boundary)

        let longitude = locationInfo?.coordinate.longitude ?? 0
        body.appendFormField(name: "longitude", value: String(longitude), boundary: boundary)

        if !interests.isEmpty {
            for interest in interests {
                body.appendFormField(name: "user_interests", value: interest.id, boundary: boundary)
            }
        }

        if let ageGroup = preferences.ageGroup {
            body.appendFormField(name: "user_age_group", value: ageGroup.rawValue, boundary: boundary)
        }

        if let budgetLevel = preferences.budgetLevel {
            body.appendFormField(name: "user_budget_level", value: budgetLevel.rawValue, boundary: boundary)
        }

        if let activityLevel = preferences.activityLevel {
            body.appendFormField(name: "user_activity_level", value: activityLevel.rawValue, boundary: boundary)
        }

        body.appendFormField(name: "user_language", value: preferences.language.rawValue, boundary: boundary)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("[VLM] 📤 Total request body size: \(body.count) bytes")

        let startTime = Date()
        let (data, response) = try await session.data(for: request)
        let elapsed = Date().timeIntervalSince(startTime)

        print("[VLM] ⏱️ Response received in \(String(format: "%.2f", elapsed)) seconds")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[VLM] ❌ Invalid response type")
            throw VLMError.invalidResponse
        }

        print("[VLM] 📥 HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("[VLM] ❌ HTTP Error: \(httpResponse.statusCode)")
            throw VLMError.httpError(statusCode: httpResponse.statusCode)
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("[VLM] 📦 Response body: \(responseString)")
        }

        let vlmResponse = try JSONDecoder().decode(VLMResponse.self, from: data)

        print("[VLM] 📋 API Response:")
        print("[VLM]   - success: \(vlmResponse.success)")
        print("[VLM]   - error_message: \(vlmResponse.errorMessage ?? "nil")")
        print("[VLM]   - generated_text: \(vlmResponse.generatedText)")

        guard vlmResponse.success else {
            print("[VLM] ❌ API Error: \(vlmResponse.errorMessage ?? "Unknown error")")
            throw VLMError.apiError(message: vlmResponse.errorMessage ?? "Unknown error")
        }

        let landmarkResponse = parseGeneratedText(vlmResponse.generatedText)

        print("[VLM] 🏛️ Parsed result:")
        print("[VLM]   - name: \(landmarkResponse.name)")
        print("[VLM]   - yearBuilt: \(landmarkResponse.yearBuilt)")
        print("[VLM]   - history: \(landmarkResponse.history.prefix(100))...")

        return Landmark(
            name: landmarkResponse.name,
            yearBuilt: landmarkResponse.yearBuilt,
            subtitle: landmarkResponse.subtitle,
            history: landmarkResponse.history
        )
    }

    private func parseGeneratedText(_ text: String) -> LandmarkAPIResponse {
        return LandmarkAPIResponse(plainText: text)
    }

}

// MARK: - Data Extension for Multipart Form

private extension Data {
    mutating func appendFormField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }
}

enum VLMError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parsingFailed:
            return "Failed to parse landmark data from response"
        }
    }
}
