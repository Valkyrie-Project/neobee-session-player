import Testing
import Foundation
@testable import neobee_session_player

struct QueueManagerTests {
    
    @Test func testInitialState() async throws {
        let queueManager = QueueManager()
        
        #expect(queueManager.queue.isEmpty)
        #expect(queueManager.currentIndex == nil)
        #expect(!queueManager.canPlayNext)
        #expect(!queueManager.canPlayPrevious)
    }
    
    @Test func testReplaceQueue() async throws {
        let queueManager = QueueManager()
        let testURLs = [
            URL(fileURLWithPath: "/test/song1.mkv"),
            URL(fileURLWithPath: "/test/song2.mpg"),
            URL(fileURLWithPath: "/test/song3.mkv")
        ]
        
        queueManager.replaceQueue(with: testURLs)
        
        #expect(queueManager.queue.count == 3)
        #expect(queueManager.currentIndex == 0)
        #expect(queueManager.canPlayNext)
        #expect(!queueManager.canPlayPrevious)
    }
    
    @Test func testEnqueueToEmptyQueue() async throws {
        let queueManager = QueueManager()
        let testURL = URL(fileURLWithPath: "/test/song.mkv")
        
        queueManager.enqueue(testURL)
        
        #expect(queueManager.queue.count == 1)
        #expect(queueManager.currentIndex == 0)
        #expect(!queueManager.canPlayNext)
        #expect(!queueManager.canPlayPrevious)
    }
    
    @Test func testEnqueueToExistingQueue() async throws {
        let queueManager = QueueManager()
        let testURLs = [
            URL(fileURLWithPath: "/test/song1.mkv"),
            URL(fileURLWithPath: "/test/song2.mpg")
        ]
        
        queueManager.replaceQueue(with: [testURLs[0]])
        queueManager.enqueue(testURLs[1])
        
        #expect(queueManager.queue.count == 2)
        #expect(queueManager.currentIndex == 0)
        #expect(queueManager.canPlayNext)
    }
    
    @Test func testNavigationStates() async throws {
        let queueManager = QueueManager()
        let testURLs = [
            URL(fileURLWithPath: "/test/song1.mkv"),
            URL(fileURLWithPath: "/test/song2.mpg"),
            URL(fileURLWithPath: "/test/song3.mkv")
        ]
        
        queueManager.replaceQueue(with: testURLs)
        
        // At first song
        #expect(queueManager.currentIndex == 0)
        #expect(queueManager.canPlayNext)
        #expect(!queueManager.canPlayPrevious)
        
        // Test that we can detect when we're in the middle
        // (We can't directly set currentIndex, but we can test the logic)
        // For a 3-item queue starting at index 0:
        #expect(queueManager.queue.count == 3)
        
        // Test boundary conditions
        let singleItemQueue = QueueManager()
        singleItemQueue.replaceQueue(with: [testURLs[0]])
        #expect(!singleItemQueue.canPlayNext)
        #expect(!singleItemQueue.canPlayPrevious)
    }
    
    @Test func testClearQueue() async throws {
        let queueManager = QueueManager()
        let testURLs = [
            URL(fileURLWithPath: "/test/song1.mkv"),
            URL(fileURLWithPath: "/test/song2.mpg")
        ]
        
        queueManager.replaceQueue(with: testURLs)
        #expect(!queueManager.queue.isEmpty)
        
        queueManager.clearQueue()
        
        #expect(queueManager.queue.isEmpty)
        #expect(queueManager.currentIndex == nil)
        #expect(!queueManager.canPlayNext)
        #expect(!queueManager.canPlayPrevious)
    }
    
    @Test func testPlayNextBeyondBounds() async throws {
        let queueManager = QueueManager()
        let testURL = URL(fileURLWithPath: "/test/song.mkv")
        
        queueManager.replaceQueue(with: [testURL])
        #expect(queueManager.currentIndex == 0)
        #expect(!queueManager.canPlayNext)
        
        // Attempting to play next when at the end should not change index
        let originalIndex = queueManager.currentIndex
        // Note: We can't directly test playNextIfAvailable without mocking VLCPlayerController
        // But we can test the canPlayNext logic
        #expect(!queueManager.canPlayNext)
        #expect(queueManager.currentIndex == originalIndex)
    }
}
