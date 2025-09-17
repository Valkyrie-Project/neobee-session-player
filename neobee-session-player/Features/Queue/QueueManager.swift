import Foundation

final class QueueManager: ObservableObject {
    static let shared = QueueManager()

    @Published private(set) var queue: [URL] = []
    @Published private(set) var currentIndex: Int? = nil
    
    private let queueKey = "PlaybackQueue"
    private let currentIndexKey = "CurrentQueueIndex"

    init() {
        loadPersistedQueue()
    }

    func replaceQueue(with urls: [URL]) {
        queue = urls
        currentIndex = 0
        saveQueue()
    }

    func enqueue(_ url: URL) {
        queue.append(url)
        if currentIndex == nil {
            currentIndex = 0
            VLCPlayerController.shared.play(url: url)
        }
        saveQueue()
    }

    func playNextIfAvailable() {
        guard let idx = currentIndex else { return }
        let next = idx + 1
        guard next < queue.count else { return }
        currentIndex = next
        VLCPlayerController.shared.play(url: queue[next])
        saveCurrentIndex()
    }

    func playPreviousIfAvailable() {
        guard let idx = currentIndex else { return }
        let prev = idx - 1
        guard prev >= 0, prev < queue.count else { return }
        currentIndex = prev
        VLCPlayerController.shared.play(url: queue[prev])
        saveCurrentIndex()
    }

    var canPlayNext: Bool {
        guard let idx = currentIndex else { return false }
        return idx + 1 < queue.count
    }

    var canPlayPrevious: Bool {
        guard let idx = currentIndex else { return false }
        return idx - 1 >= 0
    }
    
    // MARK: - Persistence
    
    private func saveQueue() {
        let urls = queue.map { $0.absoluteString }
        UserDefaults.standard.set(urls, forKey: queueKey)
        saveCurrentIndex()
    }
    
    private func saveCurrentIndex() {
        if let index = currentIndex {
            UserDefaults.standard.set(index, forKey: currentIndexKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentIndexKey)
        }
    }
    
    private func loadPersistedQueue() {
        guard let urlStrings = UserDefaults.standard.array(forKey: queueKey) as? [String] else {
            return
        }
        
        queue = urlStrings.compactMap { URL(string: $0) }
        
        if UserDefaults.standard.object(forKey: currentIndexKey) != nil {
            let index = UserDefaults.standard.integer(forKey: currentIndexKey)
            if index >= 0 && index < queue.count {
                currentIndex = index
            }
        }
        
        NSLog("[QueueManager] Loaded persisted queue with \(queue.count) items, current index: \(currentIndex?.description ?? "nil")")
    }
    
    func clearQueue() {
        queue.removeAll()
        currentIndex = nil
        UserDefaults.standard.removeObject(forKey: queueKey)
        UserDefaults.standard.removeObject(forKey: currentIndexKey)
    }
}


