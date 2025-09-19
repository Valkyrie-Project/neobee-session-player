//
//  MenuBarManager.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 19/09/2025.
//

import Foundation
import AppKit
import SwiftUI
import Combine

final class MenuBarManager: ObservableObject {
    static let shared = MenuBarManager()
    
    @Published var isPlaying: Bool = false
    @Published var currentSongTitle: String = "无歌曲"
    @Published var currentArtist: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupMenuBar()
        observePlayerChanges()
    }
    
    // MARK: - Application Menu Bar
    
    private func setupMenuBar() {
        // This will be handled by the main app's menu system
        // We can customize it in the AppDelegate
    }
    
    // MARK: - Player State Observation
    
    private func observePlayerChanges() {
        let controller = VLCPlayerController.shared
        
        // Reactively mirror isPlaying and currentURL, no polling
        controller.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                self?.isPlaying = playing
            }
            .store(in: &cancellables)
        
        controller.$currentURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                if let url {
                    let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
                    self?.currentSongTitle = nameWithoutExtension
                    self?.currentArtist = "" // You can extract artist info if available
                } else {
                    self?.currentSongTitle = "无歌曲"
                    self?.currentArtist = ""
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func togglePlayPause() {
        VLCPlayerController.shared.togglePlayPause()
    }
    
    @objc private func playPrevious() {
        QueueManager.shared.playPreviousIfAvailable()
    }
    
    @objc private func playNext() {
        QueueManager.shared.playNextIfAvailable()
    }
    
    @objc private func selectOriginalTrack() {
        VLCPlayerController.shared.selectOriginalTrack()
    }
    
    @objc private func selectAccompanimentTrack() {
        VLCPlayerController.shared.selectAccompanimentTrack()
    }
    
    @objc private func addFolder() {
        // Trigger library scanner to add folder
        NotificationCenter.default.post(name: .init("AddFolderRequested"), object: nil)
    }
    
    @objc private func clearLibrary() {
        // Trigger library scanner to clear database
        NotificationCenter.default.post(name: .init("ClearLibraryRequested"), object: nil)
    }
    
    @objc private func showMainWindow() {
        if let window = NSApp.keyWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc private func playerStateChanged() {
        // No-op; we now update reactively via Combine
    }
}

// MARK: - Application Menu Customization

extension MenuBarManager {
    
    static func customizeApplicationMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        
        // Clear all existing menus and create custom ones
        mainMenu.removeAllItems()
        
        // 1. App Menu (NeoBee KTV播放器)
        let appMenu = NSMenu(title: "NeoBee KTV播放器")
        let appMenuItem = NSMenuItem(title: "NeoBee KTV播放器", action: nil, keyEquivalent: "")
        appMenuItem.submenu = appMenu
        
        let aboutItem = NSMenuItem(title: "关于 NeoBee KTV播放器", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = MenuBarManager.shared
        appMenu.addItem(aboutItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let hideItem = NSMenuItem(title: "隐藏 NeoBee KTV播放器", action: #selector(hideApp), keyEquivalent: "h")
        hideItem.target = MenuBarManager.shared
        appMenu.addItem(hideItem)
        
        let hideOthersItem = NSMenuItem(title: "隐藏其他", action: #selector(hideOtherApps), keyEquivalent: "h")
        hideOthersItem.target = MenuBarManager.shared
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        
        let showAllItem = NSMenuItem(title: "显示全部", action: #selector(showAllApps), keyEquivalent: "")
        showAllItem.target = MenuBarManager.shared
        appMenu.addItem(showAllItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出 NeoBee KTV播放器", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = MenuBarManager.shared
        appMenu.addItem(quitItem)
        
        mainMenu.addItem(appMenuItem)
        
        // 2. 播放控制菜单
        let playMenu = NSMenu(title: "播放控制")
        let playMenuItem = NSMenuItem(title: "播放控制", action: nil, keyEquivalent: "")
        playMenuItem.submenu = playMenu
        
        let playPauseItem = NSMenuItem(title: "播放/暂停", action: #selector(togglePlayPause), keyEquivalent: " ")
        playPauseItem.target = MenuBarManager.shared
        playMenu.addItem(playPauseItem)
        
        let previousItem = NSMenuItem(title: "上一首", action: #selector(playPrevious), keyEquivalent: "")
        previousItem.target = MenuBarManager.shared
        playMenu.addItem(previousItem)
        
        let nextItem = NSMenuItem(title: "下一首", action: #selector(playNext), keyEquivalent: "")
        nextItem.target = MenuBarManager.shared
        playMenu.addItem(nextItem)
        
        playMenu.addItem(NSMenuItem.separator())
        
        let originalTrackItem = NSMenuItem(title: "选择原唱", action: #selector(selectOriginalTrack), keyEquivalent: "")
        originalTrackItem.target = MenuBarManager.shared
        playMenu.addItem(originalTrackItem)
        
        let accompanimentTrackItem = NSMenuItem(title: "选择伴奏", action: #selector(selectAccompanimentTrack), keyEquivalent: "")
        accompanimentTrackItem.target = MenuBarManager.shared
        playMenu.addItem(accompanimentTrackItem)
        
        playMenu.addItem(NSMenuItem.separator())
        
        let stopItem = NSMenuItem(title: "停止播放", action: #selector(stopPlayback), keyEquivalent: "")
        stopItem.target = MenuBarManager.shared
        playMenu.addItem(stopItem)
        
        mainMenu.addItem(playMenuItem)
        
        // 3. 歌单菜单
        let libraryMenu = NSMenu(title: "歌单")
        let libraryMenuItem = NSMenuItem(title: "歌单", action: nil, keyEquivalent: "")
        libraryMenuItem.submenu = libraryMenu
        
        let addFolderMenuItem = NSMenuItem(title: "添加歌单文件夹...", action: #selector(importFolder), keyEquivalent: "o")
        addFolderMenuItem.target = MenuBarManager.shared
        libraryMenu.addItem(addFolderMenuItem)
        
        let clearLibraryMenuItem = NSMenuItem(title: "清理歌单", action: #selector(clearLibrary), keyEquivalent: "")
        clearLibraryMenuItem.target = MenuBarManager.shared
        libraryMenu.addItem(clearLibraryMenuItem)
        
        libraryMenu.addItem(NSMenuItem.separator())
        
        let searchItem = NSMenuItem(title: "搜索歌曲...", action: #selector(focusSearch), keyEquivalent: "f")
        searchItem.target = MenuBarManager.shared
        libraryMenu.addItem(searchItem)
        
        mainMenu.addItem(libraryMenuItem)
        
        // 4. 窗口菜单 - 简化版本
        let windowMenu = NSMenu(title: "窗口")
        let windowMenuItem = NSMenuItem(title: "窗口", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        
        // 只保留真正有用的窗口操作
        let minimizeItem = NSMenuItem(title: "最小化", action: #selector(minimizeWindow), keyEquivalent: "m")
        minimizeItem.target = MenuBarManager.shared
        windowMenu.addItem(minimizeItem)
        
        let fullScreenItem = NSMenuItem(title: "进入全屏", action: #selector(toggleFullScreen), keyEquivalent: "f")
        fullScreenItem.target = MenuBarManager.shared
        windowMenu.addItem(fullScreenItem)
        
        mainMenu.addItem(windowMenuItem)
        
        // 5. 帮助菜单
        let helpMenu = NSMenu(title: "帮助")
        let helpMenuItem = NSMenuItem(title: "帮助", action: nil, keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        
        let helpItem = NSMenuItem(title: "NeoBee KTV播放器帮助", action: #selector(showHelp), keyEquivalent: "?")
        helpItem.target = MenuBarManager.shared
        helpMenu.addItem(helpItem)
        
        mainMenu.addItem(helpMenuItem)
    }
    
    @objc private func showAbout() {
        // Show about dialog
        let alert = NSAlert()
        alert.messageText = "关于 NeoBee KTV播放器"
        alert.informativeText = "版本 1.0\n\nNeoBee KTV播放器是一个专为KTV场景设计的音乐播放应用。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func hideApp() {
        NSApp.hide(nil)
    }
    
    @objc private func hideOtherApps() {
        NSApp.hideOtherApplications(nil)
    }
    
    @objc private func showAllApps() {
        NSApp.unhideAllApplications(nil)
    }
    
    @objc private func stopPlayback() {
        VLCPlayerController.shared.stop()
    }
    
    @objc private func minimizeWindow() {
        if let window = NSApp.keyWindow {
            window.miniaturize(nil)
        }
    }
    
    @objc private func toggleFullScreen() {
        if let window = NSApp.keyWindow {
            window.toggleFullScreen(nil)
        }
    }
    
    @objc private func showHelp() {
        // 改为发通知，由主界面以 SwiftUI Sheet 弹出帮助视图（非阻塞）
        NotificationCenter.default.post(name: .init("ShowHelpRequested"), object: nil)
    }
    
    @objc private func importFolder() {
        addFolder()
    }
    
    @objc private func focusSearch() {
        // Focus the search field in the main window
        NotificationCenter.default.post(name: .init("FocusSearchRequested"), object: nil)
    }
}
