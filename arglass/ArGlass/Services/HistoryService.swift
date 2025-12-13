import Foundation
import UIKit

actor HistoryService {
    static let shared = HistoryService()

    private let maxEntries = 50
    private let duplicateThresholdSeconds: TimeInterval = 300
    private let fileName = "history.json"
    private let imageDirectoryName = "history_images"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private var imageDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(imageDirectoryName)
    }

    private init() {
        createImageDirectoryIfNeeded()
    }

    private func createImageDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: imageDirectoryURL.path) {
            try? fileManager.createDirectory(at: imageDirectoryURL, withIntermediateDirectories: true)
        }
    }

    func loadHistory() -> [HistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            print("[History] Failed to load: \(error.localizedDescription)")
            return []
        }
    }

    func addEntry(_ entry: HistoryEntry, image: UIImage?) async {
        var entries = loadHistory()

        let recentThreshold = Date().addingTimeInterval(-duplicateThresholdSeconds)
        let isDuplicate = entries.contains { existing in
            existing.name == entry.name && existing.timestamp > recentThreshold
        }

        guard !isDuplicate else { return }

        var entryToSave = entry
        if let image = image {
            let imageFileName = "\(entry.id.uuidString).jpg"
            if saveImage(image, fileName: imageFileName) {
                entryToSave = HistoryEntry(
                    id: entry.id,
                    name: entry.name,
                    yearBuilt: entry.yearBuilt,
                    subtitle: entry.subtitle,
                    history: entry.history,
                    distanceMeters: entry.distanceMeters,
                    bearingDegrees: entry.bearingDegrees,
                    timestamp: entry.timestamp,
                    imageFileName: imageFileName
                )
            }
        }

        entries.insert(entryToSave, at: 0)

        if entries.count > maxEntries {
            let removedEntries = entries.suffix(from: maxEntries)
            for removed in removedEntries {
                deleteImage(for: removed)
            }
            entries = Array(entries.prefix(maxEntries))
        }

        await save(entries)
    }

    func deleteEntry(_ entry: HistoryEntry) async {
        var entries = loadHistory()
        entries.removeAll { $0.id == entry.id }
        deleteImage(for: entry)
        await save(entries)
    }

    func clearAll() async {
        let entries = loadHistory()
        for entry in entries {
            deleteImage(for: entry)
        }
        await save([])
    }

    func imageURL(for entry: HistoryEntry) -> URL? {
        guard let fileName = entry.imageFileName else { return nil }
        let url = imageDirectoryURL.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return false }
        let url = imageDirectoryURL.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            print("[History] Failed to save image: \(error.localizedDescription)")
            return false
        }
    }

    private func deleteImage(for entry: HistoryEntry) {
        guard let fileName = entry.imageFileName else { return }
        let url = imageDirectoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    private func save(_ entries: [HistoryEntry]) async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[History] Failed to save: \(error.localizedDescription)")
        }
    }
}
