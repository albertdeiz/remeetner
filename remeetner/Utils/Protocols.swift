//
//  Protocols.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation

// MARK: - Event Management Protocols

protocol EventScheduling: AnyObject {
    var futureEvents: [CalendarEvent] { get }
    var nextEvent: CalendarEvent? { get }
    
    func startScheduling()
    func stopScheduling()
    func adjustEventTimeTolerance(_ seconds: TimeInterval)
}

protocol BreakManaging: AnyObject {
    var isBreakActive: Bool { get }
    
    func startBreak()
    func endBreak()
}

protocol WindowManaging: AnyObject {
    var isOverlayVisible: Bool { get }
    
    func showOverlay(duration: TimeInterval, onTap: @escaping () -> Void)
    func hideOverlay()
    func showSettings()
    func showEvents()
}

protocol AudioPlaying: AnyObject {
    func playStartSound()
    func playEndSound()
}

protocol DateParsing: AnyObject {
    func parseDate(from dateString: String) -> Date?
    func debugEventDates(_ events: [CalendarEvent])
}

// MARK: - Logging Protocol

protocol Logging: AnyObject {
    func verbose(_ message: String, file: String, function: String, line: Int)
    func info(_ message: String, file: String, function: String, line: Int)
    func warning(_ message: String, file: String, function: String, line: Int)
    func error(_ message: String, file: String, function: String, line: Int)
    func error(_ error: Error, file: String, function: String, line: Int)
}

// MARK: - Coordination Protocol

protocol AppCoordinating: AnyObject {
    func handleURLOpen(_ urls: [URL])
    func performGoogleAuth()
}
