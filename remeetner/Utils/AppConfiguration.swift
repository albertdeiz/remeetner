//
//  AppConfiguration.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

/// Configuración centralizada de la aplicación
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
    
    // MARK: - Google OAuth
    static let clientID = "1036730212367-j1ekoj4ecgj0rfalkosagrsl9ntbdrrl.apps.googleusercontent.com"
    static let redirectURIString = "com.albertdeiz.remeetner:/oauthredirect"
    static let issuerURLString = "https://accounts.google.com"
    
    // MARK: - API
    static let calendarAPIBaseURL = "https://www.googleapis.com/calendar/v3"
    
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

/// Configuración para diferentes entornos
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

/// Niveles de logging
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
