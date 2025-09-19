import Foundation
import CoreData
import AVFoundation
import AppKit
import VLCKit

// MARK: - Library Scanner Service

final class LibraryScanner: ObservableObject, @unchecked Sendable {
    @Published var isScanning: Bool = false
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        if panel.runModal() == .OK, let url = panel.url {
            persistFolderAndScan(url: url)
        }
    }
    
    func clearDatabase() {
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
            Task { @MainActor in
                ErrorHandler.shared.handle(
                    AppError.coreDataError("清理数据库失败"),
                    context: "清理歌单"
                )
            }
        }
    }
    
    private func persistFolderAndScan(url: URL) {
        isScanning = true
        let folder = LibraryFolder(context: viewContext)
        folder.id = UUID()
        folder.folderURL = url.path
        // Save security-scoped bookmark so files stay accessible after relaunch
        do {
            let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            folder.bookmark = bookmark
        } catch {
            Task { @MainActor in
                ErrorHandler.shared.handle(
                    AppError.fileAccessDenied(url.path),
                    context: "创建安全作用域书签"
                )
            }
        }
        folder.createdAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            Task { @MainActor in
                ErrorHandler.shared.handle(
                    AppError.coreDataError("保存文件夹信息失败"),
                    context: "添加歌单"
                )
                self.isScanning = false
            }
            return
        }
        
        Task.detached(priority: .userInitiated) {
            await self.scanFolderAsync(url: url)
            await MainActor.run { self.isScanning = false }
        }
    }

    private func scanFolderAsync(url: URL) async {
        let fm = FileManager.default
        // 支持的视频：仅限 KTV 常用容器
        let exts = ["mkv","mpg"]
        let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        var newSongs: [(URL, String,String?,String?)] = []
        while let file = enumerator?.nextObject() as? URL {
            if (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true { continue }
            if !exts.contains(file.pathExtension.lowercased()) { continue }
            let meta = await extractMetadataAsync(url: file)
            newSongs.append((file.standardizedFileURL.resolvingSymlinksInPath(), meta.title, meta.artist, meta.album))
        }

        viewContext.performAndWait {
            for entry in newSongs {
                let fr: NSFetchRequest<Song> = Song.fetchRequest()
                let normalizedPath = entry.0.path
                fr.predicate = NSPredicate(format: "fileURL == %@", normalizedPath)
                
                do {
                    if let existing = try viewContext.fetch(fr).first {
                        // 如果标题为空则更新标题
                        if (existing.title ?? "").isEmpty { existing.title = entry.1 }
                        if existing.artist == nil { existing.artist = entry.2 }
                        if existing.album == nil { existing.album = entry.3 }
                    } else {
                        let s = Song(context: viewContext)
                        s.id = UUID()
                        s.fileURL = normalizedPath
                        s.title = entry.1
                        s.artist = entry.2
                        s.album = entry.3
                        s.duration = 0  // 不需要时长，设为0
                        s.addedAt = Date()
                    }
                } catch {
                    Task { @MainActor in
                        ErrorHandler.shared.handle(
                            AppError.coreDataError("查询歌曲信息失败"),
                            context: "扫描文件夹"
                        )
                    }
                }
            }
            
            do {
                try viewContext.save()
            } catch {
                Task { @MainActor in
                    ErrorHandler.shared.handle(
                        AppError.coreDataError("保存扫描结果失败"),
                        context: "扫描文件夹"
                    )
                }
            }
        }
    }

    private func extractMetadataAsync(url: URL) async -> (title: String, artist: String?, album: String?) {
        let asset = AVURLAsset(url: url)
        var title: String? = nil
        var artist: String? = nil
        var album: String? = nil

        if let common = try? await asset.load(.commonMetadata) {
            if let titleItem = AVMetadataItem.metadataItems(from: common, withKey: AVMetadataKey.commonKeyTitle, keySpace: .common).first,
               let v = try? await titleItem.load(.stringValue) { title = v }
            if let artistItem = AVMetadataItem.metadataItems(from: common, withKey: AVMetadataKey.commonKeyArtist, keySpace: .common).first,
               let v = try? await artistItem.load(.stringValue) { artist = v }
            if let albumItem = AVMetadataItem.metadataItems(from: common, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: .common).first,
               let v = try? await albumItem.load(.stringValue) { album = v }
        }

        let fallback = url.deletingPathExtension().lastPathComponent
        return (title ?? fallback, artist, album)
    }
}
