import Foundation
import UIKit

actor HistoryService: HistoryServiceProtocol {
    static let shared = HistoryService()

    private let maxEntries = 50
    private let duplicateThresholdSeconds: TimeInterval = 300
    private let fileName = "history.json"
    private let imageDirectoryName = "history_images"
    
    private let fileURL: URL
    private let imageDirectoryURL: URL

    nonisolated private static var defaultFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("history.json")
    }
    
    nonisolated private static var defaultImageDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("history_images")
    }

    init() {
        self.fileURL = Self.defaultFileURL
        self.imageDirectoryURL = Self.defaultImageDirectoryURL
        createImageDirectoryIfNeeded()
    }
    
    init(fileURL: URL, imageDirectoryURL: URL) {
        self.fileURL = fileURL
        self.imageDirectoryURL = imageDirectoryURL
        createImageDirectoryIfNeeded()
    }

    nonisolated private func createImageDirectoryIfNeeded() {
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
            let isSameContent = existing.description == entry.description
            let isSameName = existing.name == entry.name
            return (isSameContent || isSameName) && existing.timestamp > recentThreshold
        }

        guard !isDuplicate else {
            print("[History] Skipping duplicate entry: \(entry.name.prefix(30))...")
            return
        }

        var entryToSave = entry
        if let image = image {
            let imageFileName = "\(entry.id.uuidString).jpg"
            if saveImage(image, fileName: imageFileName) {
                entryToSave = HistoryEntry(
                    id: entry.id,
                    name: entry.name,
                    description: entry.description,
                    timestamp: entry.timestamp,
                    imageFileName: imageFileName,
                    captureOrientation: entry.captureOrientation
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
