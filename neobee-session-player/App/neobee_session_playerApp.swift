//
//  neobee_session_playerApp.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import SwiftUI
import AppKit
import VLCKit
import CoreData

@main
struct neobee_session_playerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @State private var showPlayerWindow: Bool = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: .showPlayer)) { _ in
                    showPlayerWindow = true
                }
                .onAppear { 
                    restoreSecurityScopedBookmarks()
                    // Give a small delay to ensure bookmarks are restored before loading queue
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    }
                }
        }
    }
    
    private func restoreSecurityScopedBookmarks() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<LibraryFolder> = LibraryFolder.fetchRequest()
        
        do {
            let folders = try context.fetch(request)
            for folder in folders {
                if let bookmarkData = folder.bookmark {
                    do {
                        var isStale = false
                        let url = try URL(resolvingBookmarkData: bookmarkData,
                                        options: [.withSecurityScope],
                                        relativeTo: nil,
                                        bookmarkDataIsStale: &isStale)
                        
                        if isStale {
                            // Update the bookmark if it's stale
                            if let newBookmark = try? url.bookmarkData(options: [.withSecurityScope],
                                                                     includingResourceValuesForKeys: nil,
                                                                     relativeTo: nil) {
                                folder.bookmark = newBookmark
                                try? context.save()
                            }
                        }
                        
                        // Start accessing the security-scoped resource
                        _ = url.startAccessingSecurityScopedResource()
                        
                    } catch {
                    }
                }
            }
        } catch {
        }
    }
    
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        VLCPlayerController.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Close app when user closes the last window to avoid background playback
        return true
    }
}
