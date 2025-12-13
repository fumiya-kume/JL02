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
}

actor VLMAPIClient {
    static let shared = VLMAPIClient()

    private let baseURL = URL(string: "https://ungravitative-unsedately-vanetta.ngrok-free.dev")!
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func inferLandmark(image: UIImage) async throws -> Landmark {
        let prompt = """
        この画像のランドマークをJSON形式で回答してください: {"name": "名前", "year_built": "建設年", "subtitle": "説明", "history": "歴史"}
        """

        let url = baseURL.appendingPathComponent("inference")

        print("[VLM] 🚀 Sending request to: \(url.absoluteString)")
        print("[VLM] 📝 Prompt: \(prompt)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("[VLM] ❌ Failed to convert image to JPEG")
            throw VLMError.imageConversionFailed
        }

        print("[VLM] 🖼️ Image size: \(imageData.count) bytes (\(String(format: "%.2f", Double(imageData.count) / 1024.0)) KB)")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
        body.append(prompt.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

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

        guard vlmResponse.success else {
            print("[VLM] ❌ API Error: \(vlmResponse.errorMessage ?? "Unknown error")")
            throw VLMError.apiError(message: vlmResponse.errorMessage ?? "Unknown error")
        }

        print("[VLM] ✅ Generated text: \(vlmResponse.generatedText)")

        let landmarkResponse = try parseGeneratedText(vlmResponse.generatedText)

        print("[VLM] 🏛️ Parsed landmark: \(landmarkResponse.name)")

        return Landmark(
            name: landmarkResponse.name,
            yearBuilt: landmarkResponse.yearBuilt,
            subtitle: landmarkResponse.subtitle,
            history: landmarkResponse.history,
            distanceMeters: 0,
            bearingDegrees: 0
        )
    }

    private func parseGeneratedText(_ text: String) throws -> LandmarkAPIResponse {
        guard let jsonStart = text.firstIndex(of: "{"),
              let jsonEnd = text.lastIndex(of: "}") else {
            throw VLMError.parsingFailed
        }

        let jsonString = String(text[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw VLMError.parsingFailed
        }

        return try JSONDecoder().decode(LandmarkAPIResponse.self, from: jsonData)
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
