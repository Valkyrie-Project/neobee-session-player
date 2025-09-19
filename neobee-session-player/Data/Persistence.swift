//
//  Persistence.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "neobee_session_player")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { [container] (storeDescription, error) in
            if let error = error as NSError? {
                // 使用错误处理系统而不是fatalError
                Task { @MainActor in
                    ErrorHandler.shared.handle(
                        AppError.coreDataError("CoreData存储初始化失败: \(error.localizedDescription)"),
                        context: "初始化数据存储"
                    )
                }
                
                // 记录详细错误信息用于调试
                print("❌ CoreData Error Details:")
                print("   Domain: \(error.domain)")
                print("   Code: \(error.code)")
                print("   Description: \(error.localizedDescription)")
                print("   UserInfo: \(error.userInfo)")
                
                // 尝试恢复：删除损坏的存储文件并重新创建
                Self.handleCorruptedStore(container: container, storeDescription: storeDescription)
            }
        })
        // Merge background changes into the view context and set a merge policy to reduce conflicts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// 处理损坏的CoreData存储文件
    private static func handleCorruptedStore(container: NSPersistentContainer, storeDescription: NSPersistentStoreDescription) {
        guard let storeURL = storeDescription.url else { return }
        
        do {
            // 尝试删除损坏的存储文件
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
                print("✅ 已删除损坏的存储文件: \(storeURL.path)")
            }
            
            // 删除相关的辅助文件
            let shmURL = storeURL.appendingPathExtension("sqlite-shm")
            let walURL = storeURL.appendingPathExtension("sqlite-wal")
            
            if FileManager.default.fileExists(atPath: shmURL.path) {
                try FileManager.default.removeItem(at: shmURL)
            }
            if FileManager.default.fileExists(atPath: walURL.path) {
                try FileManager.default.removeItem(at: walURL)
            }
            
            // 重新尝试加载存储
            container.loadPersistentStores { _, error in
                if error != nil {
                    Task { @MainActor in
                        ErrorHandler.shared.handle(
                            AppError.coreDataError("无法恢复数据存储，请重启应用程序"),
                            context: "恢复数据存储"
                        )
                    }
                } else {
                    print("✅ 成功恢复数据存储")
                }
            }
            
        } catch {
            Task { @MainActor in
                ErrorHandler.shared.handle(
                    AppError.coreDataError("无法删除损坏的存储文件: \(error.localizedDescription)"),
                    context: "恢复数据存储"
                )
            }
        }
    }
}

