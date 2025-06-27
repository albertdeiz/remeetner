//
//  AppConfiguration.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

/// Centralized application configuration
enum AppConfiguration {
    // MARK: - Timing
    static let eventTimeToleranceSeconds: TimeInterval = 0.5
    static let precisionTimerInterval: TimeInterval = 0.1
    static let debugTimingThreshold: TimeInterval = 10.0
    
    // MARK: - Windows
    static let overlayOpacity: Double = 0.6
    static let settingsWindowSize = CGSize(width: 300, height: 250)
    static let eventsWindowSize = CGSize(width: 320, height: 400)
    
    // MARK: - Sounds
    static let startSoundName = "Glass"
    static let endSoundName = "Ping"
    
    // MARK: - Google OAuth (Using SecureConfiguration)
    static let clientID = SecureConfiguration.clientID
    static let redirectURIString = SecureConfiguration.redirectURI
    static let issuerURLString = SecureConfiguration.issuerURL
    
    // MARK: - API
    static let calendarAPIBaseURL = SecureConfiguration.Environment.current.apiBaseURL
    
    // MARK: - Debugging
    static let isDebugMode: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    static let maxEventsToDebug = 3
    
    // MARK: - Storage Keys
    enum StorageKeys {
        static let authState = "authState"
        static let breakDuration = "breakDuration"
        static let eventRefreshInterval = "eventRefreshInterval"
    }
}

/// Configuration for different environments
enum AppEnvironment {
    case debug
    case release
    
    static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
    
    var logLevel: LogLevel {
        switch self {
        case .debug:
            return .verbose
        case .release:
            return .error
        }
    }
}

/// Logging levels
enum LogLevel: Int, CaseIterable {
    case verbose = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var emoji: String {
        switch self {
        case .verbose: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}
