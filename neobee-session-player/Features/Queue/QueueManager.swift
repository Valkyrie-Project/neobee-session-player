import Foundation

final class QueueManager: ObservableObject {
    static let shared = QueueManager()

    @Published private(set) var queue: [URL] = []
    @Published private(set) var currentIndex: Int? = nil

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
}


