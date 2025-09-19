import SwiftUI
import CoreData

struct LibraryListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var songs: FetchedResults<Song>
    let query: String

    init(query: String) {
        self.query = query
        let sort = [NSSortDescriptor(keyPath: \Song.addedAt, ascending: false)]
        let predicate = LibraryListView.makePredicate(for: query)
        _songs = FetchRequest<Song>(
            sortDescriptors: sort,
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            List(songs) { song in
                HStack {
                    VStack(alignment: .leading) {
                        Text(song.title ?? "Untitled")
                            .font(.headline)
                        Text(metaLine(for: song))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("播放") { play(song) }
                    Button("加入播放列表") { addToQueue(song) }
                }
                .contextMenu {
                    Button("播放") { play(song) }
                    Button("加入播放列表") { addToQueue(song) }
                    Divider()
                    Button("在 Finder 中显示") { revealInFinder(song) }
                    Button("删除这首", role: .destructive) { deleteSong(song) }
                }
            }
            Divider()
            QueueDisplayView()
                .padding()
        }
        // Rebuild the view with a new FetchRequest when query changes by reinitializing the view
        // Caller (ContentView) already re-renders LibraryListView(query:) when query changes.
    }

    private static func makePredicate(for query: String) -> NSPredicate? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return NSPredicate(format: "(title CONTAINS[c] %@) OR (artist CONTAINS[c] %@)", trimmed, trimmed)
    }

    private func metaLine(for song: Song) -> String {
        let parts = [song.artist, song.album].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }

    private func revealInFinder(_ song: Song) {
        guard let path = song.fileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    private func deleteSong(_ song: Song) {
        viewContext.delete(song)
        do {
            try viewContext.save()
        } catch {
            ErrorHandler.shared.handle(
                AppError.coreDataError("删除歌曲失败: \(error.localizedDescription)"),
                context: "删除歌曲"
            )
        }
    }

    private func play(_ song: Song) {
        guard let path = song.fileURL else {
            ErrorHandler.shared.handle(
                AppError.fileNotFound("歌曲文件路径为空"),
                context: "播放歌曲"
            )
            return
        }
        let url = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: path) {
            ErrorHandler.shared.handle(AppError.fileNotFound(path), context: "播放歌曲")
            return
        }
        VLCPlayerController.shared.play(url: url)
        QueueManager.shared.replaceQueue(with: [url])
    }

    private func addToQueue(_ song: Song) {
        guard let path = song.fileURL else {
            ErrorHandler.shared.handle(
                AppError.fileNotFound("歌曲文件路径为空"),
                context: "添加到播放列表"
            )
            return
        }
        if !FileManager.default.fileExists(atPath: path) {
            ErrorHandler.shared.handle(AppError.fileNotFound(path), context: "添加到播放列表")
            return
        }
        QueueManager.shared.enqueue(URL(fileURLWithPath: path))
    }
}
