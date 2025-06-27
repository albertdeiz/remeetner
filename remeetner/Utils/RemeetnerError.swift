//
//  RemeetnerError.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

/// Specific errors for the Remeetner application
enum RemeetnerError: LocalizedError {
    case authenticationFailed
    case eventsFetchFailed
    case dateParsingFailed(String)
    case windowCreationFailed
    case googleAPIError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Could not authenticate with Google Calendar"
        case .eventsFetchFailed:
            return "Could not load calendar events"
        case .dateParsingFailed(let dateString):
            return "Could not process date: \(dateString)"
        case .windowCreationFailed:
            return "Could not create window"
        case .googleAPIError(let message):
            return "Google API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Try signing out and reconnecting your Google account"
        case .eventsFetchFailed:
            return "Check your internet connection and calendar permissions"
        case .dateParsingFailed:
            return "Contact technical support with this information"
        case .windowCreationFailed:
            return "Restart the application"
        case .googleAPIError:
            return "Check your connection and Google Calendar permissions"
        case .networkError:
            return "Check your internet connection"
        }
    }
}
