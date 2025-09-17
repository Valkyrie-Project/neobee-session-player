//
//  ContentView.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import SwiftUI
import CoreData
import VLCKit
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State private var query: String = ""
    @State private var isFullScreen: Bool = false
    @StateObject private var libraryScanner: LibraryScanner
    
    init() {
        // We need to initialize with a placeholder, then update in onAppear
        self._libraryScanner = StateObject(wrappedValue: LibraryScanner(viewContext: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Always-visible player
            PlayerView(isEmbedded: !isFullScreen)
                .frame(minWidth: isFullScreen ? nil : 600)
                .background(Color.black)
                .layoutPriority(1)

            // Right: Library controls + list (hidden in full screen)
            if !isFullScreen {
                Divider()
                
                VStack(spacing: 0) {
                    HStack {
                        Button("添加歌单") { libraryScanner.addFolder() }
                        Button("清理歌单", role: .destructive) { libraryScanner.clearDatabase() }
                        Spacer()
                        TextField("搜索标题/艺人", text: $query)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 320)
                    }
                    .padding(8)
                    .background(.bar)

                    LibraryListView(query: query)
                        .overlay(alignment: .topTrailing) {
                            if libraryScanner.isScanning { ProgressView().padding() }
                        }
                }
                .frame(minWidth: 360)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            // No animation for better performance
            isFullScreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            // No animation for better performance
            isFullScreen = false
        }
        .onAppear {
            // Check initial full screen state
            isFullScreen = NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
        }
        .focusable()
        .onKeyPress { keyPress in
            // F key for full screen toggle
            if keyPress.characters == "f" {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
                return .handled
            }
            // ESC key to exit full screen
            else if keyPress.key == .escape && isFullScreen {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
                return .handled
            }
            return .ignored
        }
    }

}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
