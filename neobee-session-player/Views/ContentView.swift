//
//  ContentView.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import SwiftUI
import CoreData
import VLCKit
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State private var query: String = ""
    @State private var isScanning: Bool = false
    @State private var isFullScreen: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Left: Always-visible player
            PlayerView(isEmbedded: !isFullScreen)
                .frame(minWidth: isFullScreen ? nil : 600)
                .background(Color.black)
                .layoutPriority(1)

            // Right: Library controls + list (hidden in full screen)
            if !isFullScreen {
                Divider()
                
                VStack(spacing: 0) {
                    HStack {
                        Button("添加歌单") { addFolder() }
                        Button("清理歌单", role: .destructive) { clearDatabase() }
                        Spacer()
                        TextField("搜索标题/艺人", text: $query)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 320)
                    }
                    .padding(8)
                    .background(.bar)

                    LibraryListView(query: query)
                        .overlay(alignment: .topTrailing) {
                            if isScanning { ProgressView().padding() }
                        }
                }
                .frame(minWidth: 360)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            // No animation for better performance
            isFullScreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            // No animation for better performance
            isFullScreen = false
        }
        .onAppear {
            // Check initial full screen state
            isFullScreen = NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
        }
        .focusable()
        .onKeyPress { keyPress in
            // F key for full screen toggle
            if keyPress.characters == "f" {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
                return .handled
            }
            // ESC key to exit full screen
            else if keyPress.key == .escape && isFullScreen {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
                return .handled
            }
            return .ignored
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        if panel.runModal() == .OK, let url = panel.url {
            persistFolderAndScan(url: url)
        }
    }

    private func clearDatabase() {
        do {
            // Delete Songs
            let songFR: NSFetchRequest<NSFetchRequestResult> = Song.fetchRequest()
            let songDel = NSBatchDeleteRequest(fetchRequest: songFR)
            songDel.resultType = .resultTypeObjectIDs
            if let result = try viewContext.execute(songDel) as? NSBatchDeleteResult,
               let ids = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [viewContext])
            }

            // Delete Library Folders
            let folderFR: NSFetchRequest<NSFetchRequestResult> = LibraryFolder.fetchRequest()
            let folderDel = NSBatchDeleteRequest(fetchRequest: folderFR)
            folderDel.resultType = .resultTypeObjectIDs
            if let result = try viewContext.execute(folderDel) as? NSBatchDeleteResult,
               let ids = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [viewContext])
            }

            try viewContext.save()
            
            // Also clear the playback queue
            QueueManager.shared.clearQueue()
            
        } catch {
            NSLog("[Library] Clear DB error: \(error.localizedDescription)")
        }
    }

    private func persistFolderAndScan(url: URL) {
        isScanning = true
        let folder = LibraryFolder(context: viewContext)
        folder.id = UUID()
        folder.folderURL = url.path
        // Save security-scoped bookmark so files stay accessible after relaunch
        if let bookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
            folder.bookmark = bookmark
        }
        folder.createdAt = Date()
        do { try viewContext.save() } catch { NSLog("[Library] save folder: \(error.localizedDescription)") }
        Task.detached(priority: .userInitiated) {
            await scanFolderAsync(url: url)
            await MainActor.run { isScanning = false }
        }
    }

    private func scanFolderAsync(url: URL) async {
        let fm = FileManager.default
        // 支持的视频/音频扩展；加入 mkv、mpg/mpeg
        let exts = ["mp4","mkv","mpg","mpeg","mov","avi","mp3","aac","flac","wav","m4a"]
        let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        var newSongs: [(URL, String,String?,String?,Double?)] = []
        while let file = enumerator?.nextObject() as? URL {
            if (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true { continue }
            if !exts.contains(file.pathExtension.lowercased()) { continue }
            let meta = await extractMetadataAsync(url: file)
            newSongs.append((file.standardizedFileURL.resolvingSymlinksInPath(), meta.title, meta.artist, meta.album, meta.duration))
        }

        viewContext.performAndWait {
            for entry in newSongs {
                let fr: NSFetchRequest<Song> = Song.fetchRequest()
                let normalizedPath = entry.0.path
                fr.predicate = NSPredicate(format: "fileURL == %@", normalizedPath)
                if let count = try? viewContext.count(for: fr), count > 0 { continue }
                let s = Song(context: viewContext)
                s.id = UUID()
                s.fileURL = normalizedPath
                s.title = entry.1
                s.artist = entry.2
                s.album = entry.3
                s.duration = entry.4 ?? 0
                s.addedAt = Date()
            }
            do { try viewContext.save() } catch { NSLog("[Library] save songs: \(error.localizedDescription)") }
        }
    }

    private func extractMetadataAsync(url: URL) async -> (title: String, artist: String?, album: String?, duration: Double?) {
        let asset = AVURLAsset(url: url)
        var durationSeconds: Double? = nil
        var title: String? = nil
        var artist: String? = nil
        var album: String? = nil

        if let duration = try? await asset.load(.duration) {
            durationSeconds = CMTimeGetSeconds(duration)
        }

        if let common = try? await asset.load(.commonMetadata) {
            if let titleItem = AVMetadataItem.metadataItems(from: common, withKey: AVMetadataKey.commonKeyTitle, keySpace: .common).first,
               let v = try? await titleItem.load(.stringValue) { title = v }
            if let artistItem = AVMetadataItem.metadataItems(from: common, withKey: AVMetadataKey.commonKeyArtist, keySpace: .common).first,
               let v = try? await artistItem.load(.stringValue) { artist = v }
            if let albumItem = AVMetadataItem.metadataItems(from: common, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: .common).first,
               let v = try? await albumItem.load(.stringValue) { album = v }
        }

        let fallback = url.deletingPathExtension().lastPathComponent
        return (title ?? fallback, artist, album, durationSeconds)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
