import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScanlinesOverlay()
                    .opacity(0.15)
                    .ignoresSafeArea()

                if viewModel.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle(NSLocalizedString("history_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.isEmpty {
                        Button(NSLocalizedString("history_clear_all", comment: "")) {
                            viewModel.showingClearConfirmation = true
                        }
                        .foregroundStyle(.red.opacity(0.8))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
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

    private var historyList: some View {
        List {
            ForEach(viewModel.sortedDates, id: \.self) { date in
                Section {
                    ForEach(viewModel.groupedByDate[date] ?? []) { entry in
                        HistoryEntryRow(
                            entry: entry,
                            isExpanded: viewModel.isExpanded(entry),
                            formattedTime: viewModel.formatTimestamp(entry.timestamp),
                            imageURL: viewModel.imageURLs[entry.id],
                            onTap: { viewModel.toggleExpanded(entry) }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteEntry(entry) }
                            } label: {
                                Label(NSLocalizedString("history_delete", comment: ""), systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(viewModel.formatDateHeader(date))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

#Preview {
    HistoryView()
}
