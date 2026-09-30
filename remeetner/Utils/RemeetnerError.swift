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
    case calendarPermissionMissing
    case calendarAPIDisabled
    case sessionExpired
    
    /// Whether the user has to sign in again to fix the error
    var requiresReauthentication: Bool {
        switch self {
        case .authenticationFailed, .calendarPermissionMissing, .sessionExpired:
            return true
        default:
            return false
        }
    }
    
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
        case .calendarPermissionMissing:
            return "Calendar access was not granted"
        case .calendarAPIDisabled:
            return "Google Calendar API is not enabled for this app"
        case .sessionExpired:
            return "Your Google session expired"
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
        case .calendarPermissionMissing:
            return "Reconnect and check the \"See your calendar events\" box on Google's consent screen"
        case .calendarAPIDisabled:
            return "Enable the Google Calendar API in the Google Cloud project"
        case .sessionExpired:
            return "Reconnect your Google account"
        }
    }
}
