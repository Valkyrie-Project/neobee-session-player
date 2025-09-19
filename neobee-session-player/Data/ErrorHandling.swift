//
//  ErrorHandling.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import Foundation
import SwiftUI

// MARK: - 错误类型定义

enum AppError: LocalizedError, Equatable {
    case fileNotFound(String)
    case fileAccessDenied(String)
    case unsupportedFileFormat(String)
    case mediaLoadFailed(String)
    case coreDataError(String)
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "文件未找到: \(path)"
        case .fileAccessDenied(let path):
            return "文件访问被拒绝: \(path)"
        case .unsupportedFileFormat(let format):
            return "不支持的文件格式: \(format)"
        case .mediaLoadFailed(let reason):
            return "媒体加载失败: \(reason)"
        case .coreDataError(let reason):
            return "数据存储错误: \(reason)"
        case .networkError(let reason):
            return "网络错误: \(reason)"
        case .unknown(let reason):
            return "未知错误: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "请检查文件路径是否正确，或重新添加文件到库中。"
        case .fileAccessDenied:
            return "请检查文件权限，或重新授权访问该文件夹。"
        case .unsupportedFileFormat:
            return "请使用支持的格式：MKV、MPG。"
        case .mediaLoadFailed:
            return "请检查文件是否损坏，或尝试重新加载。"
        case .coreDataError:
            return "请尝试重启应用程序。"
        case .networkError:
            return "请检查网络连接。"
        case .unknown:
            return "请尝试重启应用程序，如果问题持续存在请联系开发者。"
        }
    }
}

// MARK: - 错误处理管理器

@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let appError: AppError
        
        if let appErr = error as? AppError {
            appError = appErr
        } else {
            // 将系统错误转换为应用错误
            appError = .unknown("\(context.isEmpty ? "" : "\(context): ")\(error.localizedDescription)")
        }
        
        currentError = appError
        showErrorAlert = true
        
        // 记录错误日志
        logError(appError, context: context)
    }
    
    func handle(_ appError: AppError, context: String = "") {
        currentError = appError
        showErrorAlert = true
        logError(appError, context: context)
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
    
    private func logError(_ error: AppError, context: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let contextInfo = context.isEmpty ? "" : " [\(context)]"
        print("❌ [\(timestamp)]\(contextInfo) \(error.localizedDescription)")
        
        // 这里可以添加更高级的日志记录，比如发送到崩溃报告服务
    }
}

// MARK: - 错误显示视图

struct ErrorAlertView: View {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    var body: some View {
        EmptyView()
            .alert("错误", isPresented: $errorHandler.showErrorAlert) {
                Button("确定") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.localizedDescription)
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
    }
}

// MARK: - 扩展和工具

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

// MARK: - 安全执行函数

@MainActor
func safeExecute<T>(
    _ operation: () throws -> T,
    fallback: T? = nil,
    context: String = ""
) -> T? {
    do {
        return try operation()
    } catch {
        ErrorHandler.shared.handle(error, context: context)
        return fallback
    }
}

func safeExecuteAsync<T>(
    _ operation: () async throws -> T,
    fallback: T? = nil,
    context: String = ""
) async -> T? {
    do {
        return try await operation()
    } catch {
        await MainActor.run {
            ErrorHandler.shared.handle(error, context: context)
        }
        return fallback
    }
}
