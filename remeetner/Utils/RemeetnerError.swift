//
//  RemeetnerError.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

/// Errores específicos de la aplicación Remeetner
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
            return "No se pudo autenticar con Google Calendar"
        case .eventsFetchFailed:
            return "No se pudieron cargar los eventos del calendario"
        case .dateParsingFailed(let dateString):
            return "No se pudo procesar la fecha: \(dateString)"
        case .windowCreationFailed:
            return "No se pudo crear la ventana"
        case .googleAPIError(let message):
            return "Error de Google API: \(message)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Intenta cerrar sesión y volver a conectar tu cuenta de Google"
        case .eventsFetchFailed:
            return "Verifica tu conexión a internet y permisos de calendario"
        case .dateParsingFailed:
            return "Contacta al soporte técnico con esta información"
        case .windowCreationFailed:
            return "Reinicia la aplicación"
        case .googleAPIError:
            return "Verifica tu conexión y permisos de Google Calendar"
        case .networkError:
            return "Verifica tu conexión a internet"
        }
    }
}
