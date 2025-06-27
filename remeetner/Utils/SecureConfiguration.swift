//
//  SecureConfiguration.swift
//  remeetner
//
//  Created by Alberto Diaz on 27-06-25.
//

import Foundation

/// Secure configuration manager for handling sensitive data
enum SecureConfiguration {
    
    // MARK: - Configuration File Names
    private static let googleServiceFileName = "GoogleService-Info"
    private static let configFileName = "Config"
    
    // MARK: - Google OAuth Configuration
    static let clientID: String = {
        return getValue(for: "CLIENT_ID", from: googleServiceFileName)
    }()
    
    static let redirectURI: String = {
        return getValue(for: "REDIRECT_URI", from: googleServiceFileName)
    }()
    
    static let issuerURL: String = {
        return getValue(for: "ISSUER_URL", from: googleServiceFileName)
    }()
    
    // MARK: - Private Helper Methods
    private static func getValue(for key: String, from fileName: String) -> String {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let value = plist[key] as? String else {
            
            // Fallback: try to get from main Info.plist
            if let infoPlist = Bundle.main.infoDictionary,
               let fallbackValue = infoPlist[key] as? String {
                return fallbackValue
            }
            
            fatalError("❌ \(key) not found in \(fileName).plist or Info.plist")
        }
        return value
    }
    
    // MARK: - Environment Detection
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Validation
    static func validateConfiguration() {
        let requiredKeys = [
            ("CLIENT_ID", clientID),
            ("REDIRECT_URI", redirectURI),
            ("ISSUER_URL", issuerURL)
        ]
        
        for (key, value) in requiredKeys {
            guard !value.isEmpty else {
                fatalError("❌ Configuration validation failed: \(key) is empty")
            }
        }
        
        if isDebugBuild {
            print("✅ Configuration validation passed")
        }
    }
}

// MARK: - Environment-specific configurations
extension SecureConfiguration {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
        
        var apiBaseURL: String {
            switch self {
            case .development:
                return "https://www.googleapis.com/calendar/v3"
            case .staging:
                return "https://staging-calendar-api.googleapis.com/v3"
            case .production:
                return "https://www.googleapis.com/calendar/v3"
            }
        }
    }
}
