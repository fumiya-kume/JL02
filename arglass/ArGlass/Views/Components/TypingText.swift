import SwiftUI

struct TypingText: View {
    let text: String
    let characterDelay: Duration

    @State private var displayed = ""
    @State private var cursorOn = true

    var body: some View {
        Text(displayed + (cursorOn && !displayed.isEmpty ? "▍" : ""))
            .task(id: text) {
                await typeText()
            }
            .task {
                await blinkCursor()
            }
    }

    @MainActor
    private func typeText() async {
        displayed = ""
        for character in text {
            displayed.append(character)
            try? await Task.sleep(for: characterDelay)
            if Task.isCancelled { return }
        }
        cursorOn = false
    }

    private func blinkCursor() async {
        while !Task.isCancelled {
            await MainActor.run {
                cursorOn.toggle()
            }
            try? await Task.sleep(for: .milliseconds(420))
        }
    }
}

#Preview {
    TypingText(text: "未来的なタイピングエフェクト", characterDelay: .milliseconds(40))
        .font(.system(size: 14, weight: .semibold, design: .monospaced))
        .padding()
        .background(Color.black)
        .foregroundStyle(.white)
}

