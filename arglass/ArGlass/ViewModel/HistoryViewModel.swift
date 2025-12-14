import Foundation
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published var expandedEntryID: UUID?
    @Published var showingClearConfirmation = false
    @Published private(set) var imageURLs: [UUID: URL] = [:]
    
    private let historyService: HistoryServiceProtocol
    
    init(historyService: HistoryServiceProtocol = HistoryService.shared) {
        self.historyService = historyService
    }

    var isEmpty: Bool {
        entries.isEmpty
    }

    var groupedByDate: [Date: [HistoryEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }

    var sortedDates: [Date] {
        groupedByDate.keys.sorted(by: >)
    }

    func loadHistory() async {
        entries = await historyService.loadHistory()
        await loadImageURLs()
    }

    private func loadImageURLs() async {
        var urls: [UUID: URL] = [:]
        for entry in entries {
            if let url = await historyService.imageURL(for: entry) {
                urls[entry.id] = url
            }
        }
        imageURLs = urls
    }

    func deleteEntry(_ entry: HistoryEntry) async {
        await historyService.deleteEntry(entry)
        entries.removeAll { $0.id == entry.id }
    }

    func clearAll() async {
        await historyService.clearAll()
        entries = []
    }

    func toggleExpanded(_ entry: HistoryEntry) {
        if expandedEntryID == entry.id {
            expandedEntryID = nil
        } else {
            expandedEntryID = entry.id
        }
    }

    func isExpanded(_ entry: HistoryEntry) -> Bool {
        expandedEntryID == entry.id
    }

    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatDateHeader(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return NSLocalizedString("history_today", comment: "")
        } else if Calendar.current.isDateInYesterday(date) {
            return NSLocalizedString("history_yesterday", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    func imageURL(for entry: HistoryEntry) async -> URL? {
        await historyService.imageURL(for: entry)
    }
}
