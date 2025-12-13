import SwiftUI

struct ImageViewerView: View {
    let image: UIImage?
    let subtitle: String?
    @Environment(\.dismiss) private var dismiss
    @State private var showingExplanation = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                }

                VStack {
                    HStack {
                        if subtitle != nil {
                            infoButton
                        }
                        Spacer()
                        closeButton
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 16)
                    .padding(.horizontal, 20)

                    Spacer()

                    if showingExplanation, let subtitle = subtitle {
                        explanationPanel(subtitle: subtitle, bottomInset: geometry.safeAreaInsets.bottom)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: showingExplanation)
            }
            .onTapGesture {
                if !showingExplanation {
                    dismiss()
                } else {
                    withAnimation {
                        showingExplanation = false
                    }
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
    }

    private var infoButton: some View {
        Button(action: {
            withAnimation {
                showingExplanation.toggle()
            }
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
    }

    private func explanationPanel(subtitle: String, bottomInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(subtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16
            )
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.bottom, bottomInset)
        .onTapGesture {}
    }
}

#Preview {
    ImageViewerView(image: nil, subtitle: "銀座四丁目交差点に建つ時計塔。")
}
