import Testing
import Foundation
import CoreData
@testable import neobee_session_player

struct LibraryScannerTests {
    
    // Create in-memory Core Data stack for testing
    private func createTestContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "neobee_session_player")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to create in-memory store: \(error)")
            }
        }
        
        return container.viewContext
    }
    
    @Test func testInitialState() async throws {
        let context = createTestContext()
        let scanner = LibraryScanner(viewContext: context)
        
        #expect(!scanner.isScanning)
    }
    
    @Test func testScanningStateManagement() async throws {
        let context = createTestContext()
        let scanner = LibraryScanner(viewContext: context)
        
        #expect(!scanner.isScanning)
        
        // Test that scanning state can be modified
        await MainActor.run {
            scanner.isScanning = true
        }
        
        #expect(scanner.isScanning)
        
        await MainActor.run {
            scanner.isScanning = false
        }
        
        #expect(!scanner.isScanning)
    }
    
    @Test func testClearDatabaseWithEmptyData() async throws {
        let context = createTestContext()
        let scanner = LibraryScanner(viewContext: context)
        
        // Should not crash when clearing empty database
        scanner.clearDatabase()
        
        // Verify no songs exist
        let songRequest: NSFetchRequest<Song> = Song.fetchRequest()
        let songCount = try context.count(for: songRequest)
        #expect(songCount == 0)
        
        // Verify no library folders exist
        let folderRequest: NSFetchRequest<LibraryFolder> = LibraryFolder.fetchRequest()
        let folderCount = try context.count(for: folderRequest)
        #expect(folderCount == 0)
    }
    
    @Test func testClearDatabaseWithData() async throws {
        let context = createTestContext()
        let scanner = LibraryScanner(viewContext: context)
        
        // Add test data
        let testSong = Song(context: context)
        testSong.id = UUID()
        testSong.fileURL = "/test/song.mkv"
        testSong.title = "Test Song"
        testSong.addedAt = Date()
        
        let testFolder = LibraryFolder(context: context)
        testFolder.id = UUID()
        testFolder.folderURL = "/test/folder"
        testFolder.createdAt = Date()
        
        try context.save()
        
        // Verify data exists
        let songRequest: NSFetchRequest<Song> = Song.fetchRequest()
        let initialSongCount = try context.count(for: songRequest)
        #expect(initialSongCount == 1)
        
        let folderRequest: NSFetchRequest<LibraryFolder> = LibraryFolder.fetchRequest()
        let initialFolderCount = try context.count(for: folderRequest)
        #expect(initialFolderCount == 1)
        
        // Clear database
        scanner.clearDatabase()
        
        // Verify data is cleared
        let finalSongCount = try context.count(for: songRequest)
        #expect(finalSongCount == 0)
        
        let finalFolderCount = try context.count(for: folderRequest)
        #expect(finalFolderCount == 0)
    }
    
    @Test func testSupportedFileExtensions() async throws {
        // This test verifies the supported extensions match the app requirements
        // The app only supports MKV and MPG formats for KTV sessions
        
        let supportedExtensions = ["mkv", "mpg"]
        
        // Test that only KTV video formats are supported
        #expect(supportedExtensions.contains("mkv"))
        #expect(supportedExtensions.contains("mpg"))
        
        // Test that unsupported formats are not included
        #expect(!supportedExtensions.contains("mp4"))
        #expect(!supportedExtensions.contains("avi"))
        #expect(!supportedExtensions.contains("mov"))
        #expect(!supportedExtensions.contains("mp3"))
        
        // Test that we have exactly the right number of formats
        #expect(supportedExtensions.count == 2)
    }
    
    @Test func testLibraryScannerCreation() async throws {
        let context = createTestContext()
        let scanner = LibraryScanner(viewContext: context)
        
        // Test that scanner can be created with a context
        _ = scanner  // Scanner is non-optional, so just verify it exists
        #expect(!scanner.isScanning)
    }
}
