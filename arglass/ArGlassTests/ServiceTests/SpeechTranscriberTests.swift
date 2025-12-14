import XCTest
@testable import ArGlass

final class SpeechTranscriberTests: XCTestCase {

    // MARK: - TranscriberError Tests

    func testTranscriberError_speechNotAuthorized_description() {
        let error = SpeechTranscriber.TranscriberError.speechNotAuthorized
        XCTAssertEqual(error.errorDescription, "音声認識の権限がありません")
    }

    func testTranscriberError_microphoneNotAuthorized_description() {
        let error = SpeechTranscriber.TranscriberError.microphoneNotAuthorized
        XCTAssertEqual(error.errorDescription, "マイクの権限がありません")
    }

    func testTranscriberError_recognizerUnavailable_description() {
        let error = SpeechTranscriber.TranscriberError.recognizerUnavailable
        XCTAssertEqual(error.errorDescription, "音声認識が利用できません")
    }

    func testTranscriberError_audioSessionSetupFailed_description() {
        let error = SpeechTranscriber.TranscriberError.audioSessionSetupFailed("Test error message")
        XCTAssertEqual(error.errorDescription, "オーディオセッションの初期化に失敗しました: Test error message")
    }

    func testTranscriberError_audioSessionSetupFailed_withEmptyMessage() {
        let error = SpeechTranscriber.TranscriberError.audioSessionSetupFailed("")
        XCTAssertEqual(error.errorDescription, "オーディオセッションの初期化に失敗しました: ")
    }

    func testTranscriberError_audioSessionSetupFailed_withDetailedMessage() {
        let error = SpeechTranscriber.TranscriberError.audioSessionSetupFailed("Cannot activate audio session")
        XCTAssertEqual(error.errorDescription, "オーディオセッションの初期化に失敗しました: Cannot activate audio session")
    }
}
