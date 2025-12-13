import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var isHeaderVisible: Bool = true
    @State private var lastScrollOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    if viewModel.isEmpty {
                        headerSection(safeAreaInsets: geometry.safeAreaInsets)
                        emptyState
                    } else {
                        historyListWithHeader(safeAreaInsets: geometry.safeAreaInsets)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .task {
            await viewModel.loadHistory()
        }
        .alert(
            NSLocalizedString("history_clear_confirm_title", comment: ""),
            isPresented: $viewModel.showingClearConfirmation
        ) {
            Button(NSLocalizedString("history_cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("history_clear_all", comment: ""), role: .destructive) {
                Task {
                    await viewModel.clearAll()
                }
            }
        } message: {
            Text(NSLocalizedString("history_clear_confirm_message", comment: ""))
        }
    }

    private func headerSection(safeAreaInsets: EdgeInsets) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("history_title", comment: ""))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()

                if !viewModel.isEmpty {
                    Button(action: { viewModel.showingClearConfirmation = true }) {
                        Text(NSLocalizedString("history_clear_all", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }

                closeButton
            }
            .padding(.top, max(safeAreaInsets.top, 20) + 20)
            .hudHorizontalPadding(safeAreaInsets)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func historyListWithHeader(safeAreaInsets: EdgeInsets) -> some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    Color.clear
                        .frame(height: 80 + max(safeAreaInsets.top, 20))

                    ForEach(viewModel.sortedDates, id: \.self) { date in
                        Section {
                            ForEach(viewModel.groupedByDate[date] ?? []) { entry in
                                HistoryEntryRow(
                                    entry: entry,
                                    isExpanded: viewModel.isExpanded(entry),
                                    formattedTime: viewModel.formatTimestamp(entry.timestamp),
                                    imageURL: viewModel.imageURLs[entry.id],
                                    onTap: { viewModel.toggleExpanded(entry) },
                                    onDelete: { Task { await viewModel.deleteEntry(entry) } }
                                )
                            }
                        } header: {
                            dateHeader(viewModel.formatDateHeader(date))
                        }
                    }
                }
                .hudHorizontalPadding(safeAreaInsets)
                .padding(.bottom, 40)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let delta = value - lastScrollOffset
                if abs(delta) > 5 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if delta < 0 {
                            isHeaderVisible = false
                        } else {
                            isHeaderVisible = true
                        }
                    }
                    lastScrollOffset = value
                }
            }

            headerSection(safeAreaInsets: safeAreaInsets)
                .opacity(isHeaderVisible ? 1 : 0)
                .offset(y: isHeaderVisible ? 0 : -100)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))

            Text(NSLocalizedString("history_empty", comment: ""))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
        }
    }

    private func dateHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.black)
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
        .padding(.leading, 12)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HistoryView()
}
