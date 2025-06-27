//
//  Logger.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

/// Sistema de logging centralizado
class Logger: Logging {
    static let shared = Logger()
    
    private let logLevel: LogLevel
    private let dateFormatter: DateFormatter
    
    private init() {
        self.logLevel = AppEnvironment.current.logLevel
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= logLevel.rawValue else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "\(level.emoji) [\(timestamp)] \(filename):\(line) \(function) - \(message)"
        
        print(logMessage)
    }
    
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log(error.localizedDescription, level: .error, file: file, function: function, line: line)
    }
}
