import SwiftUI
import CoreData

struct LibraryListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Song.addedAt, ascending: false)],
        animation: .default)
    private var songs: FetchedResults<Song>

    let query: String

    var body: some View {
        VStack(spacing: 0) {
            // Songs list
            List(filteredSongs) { song in
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
            
            // Queue display area
            Divider()
            QueueDisplayView()
                .padding()
        }
    }

    private var filteredSongs: [Song] {
        guard !query.isEmpty else { return Array(songs) }
        let q = query.lowercased()
        return songs.filter { s in
            let t = (s.title ?? "").lowercased()
            let a = (s.artist ?? "").lowercased()
            return t.contains(q) || a.contains(q)
        }
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
        try? viewContext.save()
    }

    private func play(_ song: Song) {
        guard let path = song.fileURL else { return }
        let url = URL(fileURLWithPath: path)
        
        // Verify file exists before playing
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        
        VLCPlayerController.shared.play(url: url)
        QueueManager.shared.replaceQueue(with: [url])
    }

    private func addToQueue(_ song: Song) {
        guard let path = song.fileURL else { return }
        let url = URL(fileURLWithPath: path)
        
        // Verify file exists before adding to queue
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        
        QueueManager.shared.enqueue(url)
    }
}

