import Foundation

final class QueueManager: ObservableObject {
    static let shared = QueueManager()

    @Published private(set) var queue: [URL] = []
    @Published private(set) var currentIndex: Int? = nil
    

    init() {
        // Queue starts empty each time app launches
    }

    func replaceQueue(with urls: [URL]) {
        queue = urls
        currentIndex = 0
    }

    func enqueue(_ url: URL) {
        queue.append(url)
        if currentIndex == nil {
            currentIndex = 0
            VLCPlayerController.shared.play(url: url)
        }
    }

    func playNextIfAvailable() {
        guard let idx = currentIndex else { return }
        let next = idx + 1
        guard next < queue.count else { return }
        currentIndex = next
        VLCPlayerController.shared.play(url: queue[next])
    }

    func playPreviousIfAvailable() {
        guard let idx = currentIndex else { return }
        let prev = idx - 1
        guard prev >= 0, prev < queue.count else { return }
        currentIndex = prev
        VLCPlayerController.shared.play(url: queue[prev])
    }

    var canPlayNext: Bool {
        guard let idx = currentIndex else { return false }
        return idx + 1 < queue.count
    }

    var canPlayPrevious: Bool {
        guard let idx = currentIndex else { return false }
        return idx - 1 >= 0
    }
    
    
    func clearQueue() {
        queue.removeAll()
        currentIndex = nil
    }
    
    // MARK: - Queue Management
    
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        
        queue.remove(at: index)
        
        // Adjust current index if needed
        if let currentIdx = currentIndex {
            if index < currentIdx {
                // Removed item before current, decrement current index
                currentIndex = currentIdx - 1
            } else if index == currentIdx {
                // Removed current item, try to play next or stop
                if currentIdx < queue.count {
                    // Play next item at same index
                    VLCPlayerController.shared.play(url: queue[currentIdx])
                } else if currentIdx > 0 {
                    // Play previous item
                    currentIndex = currentIdx - 1
                    VLCPlayerController.shared.play(url: queue[currentIdx - 1])
                } else {
                    // No more items, stop playback
                    currentIndex = nil
                    VLCPlayerController.shared.stop()
                }
            }
        }
    }
    
    func moveToNext(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        guard let currentIdx = currentIndex else { return }
        
        // Don't move current playing song
        if index == currentIdx { return }
        
        let item = queue.remove(at: index)
        // Insert right after current playing song (at currentIdx + 1)
        let newIndex = min(currentIdx + 1, queue.count)
        queue.insert(item, at: newIndex)
        
        // No need to adjust current index since we're inserting after current
    }
    
    var currentPlayingURL: URL? {
        guard let idx = currentIndex, idx < queue.count else { return nil }
        return queue[idx]
    }
    
    var upcomingSongs: [URL] {
        guard let idx = currentIndex else { return queue }
        return Array(queue.dropFirst(idx + 1))
    }
    
    var hasSongs: Bool {
        return !queue.isEmpty
    }
}


