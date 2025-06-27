//
//  DateParser.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

/// Utilidad para parsear fechas de diferentes formatos
class DateParser: DateParsing {
    static let shared = DateParser()
    
    private let logger = Logger.shared
    
    private lazy var dateFormatters: [ISO8601DateFormatter] = {
        var formatters: [ISO8601DateFormatter] = []
        
        // Formatter 1: Con fracciones de segundo
        let formatter1 = ISO8601DateFormatter()
        formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatters.append(formatter1)
        
        // Formatter 2: Sin fracciones de segundo
        let formatter2 = ISO8601DateFormatter()
        formatter2.formatOptions = [.withInternetDateTime]
        formatters.append(formatter2)
        
        // Formatter 3: Formato más básico
        let formatter3 = ISO8601DateFormatter()
        formatter3.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        formatters.append(formatter3)
        
        return formatters
    }()
    
    private init() {}
    
    /// Intenta parsear una fecha con múltiples formatos
    func parseDate(from dateString: String) -> Date? {
        // Intentar con cada formatter ISO8601
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Si ninguno funciona, intentar con DateFormatter como último recurso
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Formato con zona horaria Z
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = fallbackFormatter.date(from: dateString) {
            return date
        }
        
        // Formato sin zona horaria
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = fallbackFormatter.date(from: dateString) {
            return date
        }
        
        // Último intento: formato más básico
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fallbackFormatter.date(from: dateString)
    }
    
    /// Debug: muestra información sobre el parsing de fechas
    func debugEventDates(_ events: [CalendarEvent]) {
        guard AppConfiguration.isDebugMode else { return }
        
        logger.verbose("=== DEBUG: Event date formats ===")
        for event in events.prefix(AppConfiguration.maxEventsToDebug) {
            if let dateTimeString = event.start.dateTime {
                logger.verbose("Event: '\(event.summary ?? "-")'")
                logger.verbose("  Original string: '\(dateTimeString)'")
                
                if let parsedDate = parseDate(from: dateTimeString) {
                    let debugFormatter = DateFormatter()
                    debugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
                    logger.verbose("  ✅ Parsed date: \(debugFormatter.string(from: parsedDate))")
                    
                    let timeInterval = parsedDate.timeIntervalSince(Date())
                    logger.verbose("  ⏱️ Difference from now: \(Int(timeInterval)) seconds")
                } else {
                    logger.error("  ❌ ERROR: Could not parse date")
                    logger.verbose("  🔍 Trying different formats...")
                    
                    // Show which formats we tried
                    for (index, formatter) in dateFormatters.enumerated() {
                        logger.verbose("  📝 Format \(index + 1): \(formatter.formatOptions)")
                    }
                }
            }
        }
        logger.verbose("=== END DEBUG ===")
    }
}
