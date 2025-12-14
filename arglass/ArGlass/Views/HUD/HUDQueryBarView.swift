import SwiftUI

struct HUDQueryBarView: View {
    @Binding var text: String
    var isListening: Bool
    var isSending: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isListening ? "waveform" : "waveform.slash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.9))

            TextField("質問を話してください…", text: $text, axis: .vertical)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .lineLimit(1...3)

            if isSending {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.accentColor.opacity(0.9))
                    .scaleEffect(0.9)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        }
        .neonGlow(color: .accentColor, radius: 14, intensity: 0.14)
    }
}

#Preview {
    ZStack {
        Color.black
        HUDQueryBarView(text: .constant("この建物は何ですか？"), isListening: true, isSending: true)
            .padding()
    }
}

