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
                .environmentObject(ErrorHandler.shared)
                .overlay(ErrorAlertView())
                .onReceive(NotificationCenter.default.publisher(for: .showPlayer)) { _ in
                    showPlayerWindow = true
                }
                .onAppear { 
                    restoreSecurityScopedBookmarks()
                    // Give a small delay to ensure bookmarks are restored before loading queue
                    DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.bookmarkRestoreDelay) {
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
                                try context.save()
                            }
                        }
                        
                        // Start accessing the security-scoped resource
                        _ = url.startAccessingSecurityScopedResource()
                        
                    } catch {
                        ErrorHandler.shared.handle(
                            AppError.fileAccessDenied(folder.folderURL ?? "未知路径"),
                            context: "恢复安全作用域书签"
                        )
                    }
                }
            }
        } catch {
            ErrorHandler.shared.handle(
                AppError.coreDataError("无法获取库文件夹列表"),
                context: "恢复安全作用域书签"
            )
        }
    }
    
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set window title when app finishes launching
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.title = "NeoBee KTV播放器"
                // Enforce a minimum window size so control panel is not occluded
                let minWidth = DesignSystem.Sizes.playerMinWidth + DesignSystem.Sizes.libraryMinWidth + DesignSystem.Spacing.windowGutter
                let minHeight = DesignSystem.Sizes.minWindowHeight
                window.minSize = NSSize(width: minWidth, height: minHeight)
                window.contentMinSize = NSSize(width: minWidth, height: minHeight)
            }
            
            // Initialize menu bar manager
            _ = MenuBarManager.shared
            
            // Customize application menu bar
            MenuBarManager.customizeApplicationMenu()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        VLCPlayerController.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Close app when user closes the last window to avoid background playback
        return true
    }
}
