import SwiftUI

struct HistoryEntryRow: View {
    let entry: HistoryEntry
    let isExpanded: Bool
    let formattedTime: String
    let imageURL: URL?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                collapsedContent

                if isExpanded {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isExpanded ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
            }
            .neonGlow(color: .accentColor, radius: isExpanded ? 12 : 0, intensity: isExpanded ? 0.12 : 0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(NSLocalizedString("history_delete", comment: ""), systemImage: "trash")
            }
        }
    }

    private var collapsedContent: some View {
        HStack(alignment: .center, spacing: 12) {
            thumbnailView
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)

                Text(entry.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            Text(formattedTime)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = imageURL, let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
        } else {
            Image(systemName: "building.columns")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.85))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            if let url = imageURL, let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                Text(entry.yearBuilt)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.white.opacity(0.06), in: Capsule(style: .continuous))

            Text(entry.history)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
