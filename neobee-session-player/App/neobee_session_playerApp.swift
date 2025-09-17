//
//  neobee_session_playerApp.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import SwiftUI
import AppKit
import VLCKit

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
                .onAppear { }
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
