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
        
        // Run scan in a structured Task (inherits cooperative cancellation)
        Task(priority: .userInitiated) {
            await self.scanFolderAsync(url: url)
            await MainActor.run { self.isScanning = false }
        }
    }

    private func scanFolderAsync(url: URL) async {
        // Start security-scoped access for the folder for the duration of the scan
        let startedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fm = FileManager.default
        // 支持的视频：仅限 KTV 常用容器
        let exts = Set(["mkv","mpg"])
        // Preload resource keys to reduce syscalls and skip packages/hidden items
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        
        // Collect candidate files (regular files with supported extensions and non-zero size)
        var candidates: [(url: URL, modDate: Date?)] = []
        while let file = enumerator?.nextObject() as? URL {
            do {
                let values = try file.resourceValues(forKeys: resourceKeys)
                if values.isDirectory == true { continue }
                if !exts.contains(file.pathExtension.lowercased()) { continue }
                if let size = values.fileSize, size == 0 { continue }
                candidates.append((file.standardizedFileURL.resolvingSymlinksInPath(), values.contentModificationDate))
            } catch {
                // Ignore unreadable entries
                continue
            }
        }
        
        if candidates.isEmpty { return }
        
        // Build a background context tied to the same store as viewContext
        guard let psc = viewContext.persistentStoreCoordinator else { return }
        let bgContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        bgContext.persistentStoreCoordinator = psc
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Prefetch existing Song.fileURL values with a single fetch (IN predicate)
        let pathStrings = candidates.map { $0.url.path }
        let existingPaths: Set<String> = bgContext.performAndWait {
            let fr: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "Song")
            fr.resultType = .dictionaryResultType
            fr.propertiesToFetch = ["fileURL"]
            fr.predicate = NSPredicate(format: "fileURL IN %@", pathStrings)
            do {
                let dicts = try bgContext.fetch(fr)
                let arr = dicts.compactMap { $0["fileURL"] as? String }
                return Set(arr)
            } catch {
                Task { @MainActor in
                    ErrorHandler.shared.handle(
                        AppError.coreDataError("查询已存在歌曲失败"),
                        context: "扫描文件夹"
                    )
                }
                return Set<String>()
            }
        }
        
        // Extract metadata and upsert in chunks to cap memory and speed up inserts
        let chunkSize = 200
        var buffer: [(url: URL, title: String, artist: String?, album: String?)] = []
        buffer.reserveCapacity(chunkSize)
        
        for entry in candidates {
            let meta = await extractMetadataAsync(url: entry.url)
            buffer.append((entry.url, meta.title, meta.artist, meta.album))
            
            if buffer.count >= chunkSize {
                upsert(buffer: buffer, existingPaths: existingPaths, context: bgContext)
                buffer.removeAll(keepingCapacity: true)
            }
        }
        if !buffer.isEmpty {
            upsert(buffer: buffer, existingPaths: existingPaths, context: bgContext)
            buffer.removeAll(keepingCapacity: true)
        }
    }
    
    private func upsert(buffer: [(url: URL, title: String, artist: String?, album: String?)],
                        existingPaths: Set<String>,
                        context: NSManagedObjectContext) {
        context.performAndWait {
            for entry in buffer {
                let normalizedPath = entry.url.path
                if existingPaths.contains(normalizedPath) {
                    // Update missing fields on existing song
                    let fr: NSFetchRequest<Song> = Song.fetchRequest()
                    fr.predicate = NSPredicate(format: "fileURL == %@", normalizedPath)
                    fr.fetchLimit = 1
                    if let existing = try? context.fetch(fr).first {
                        if (existing.title ?? "").isEmpty { existing.title = entry.title }
                        if existing.artist == nil { existing.artist = entry.artist }
                        if existing.album == nil { existing.album = entry.album }
                    }
                } else {
                    let s = Song(context: context)
                    s.id = UUID()
                    s.fileURL = normalizedPath
                    s.title = entry.title
                    s.artist = entry.artist
                    s.album = entry.album
                    s.duration = 0  // 不需要时长，设为0
                    s.addedAt = Date()
                }
            }
            do {
                if context.hasChanges {
                    try context.save()
                }
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

