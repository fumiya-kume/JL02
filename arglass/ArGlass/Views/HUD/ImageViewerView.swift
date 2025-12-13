import SwiftUI

struct ImageViewerView: View {
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss

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
                        Spacer()
                        closeButton
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 16)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .onTapGesture {
                dismiss()
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
}

#Preview {
    ImageViewerView(image: nil)
}
