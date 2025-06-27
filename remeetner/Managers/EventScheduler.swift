//
//  EventScheduler.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation
import Combine

/// Manages calendar event scheduling and tracking
class EventScheduler: ObservableObject, EventScheduling {
    @Published private(set) var futureEvents: [CalendarEvent] = []
    @Published private(set) var nextEvent: CalendarEvent?
    
    private var eventRefreshTimer: Timer?
    private var eventPrecisionTimer: Timer?
    private var triggeredEventIDs: Set<String> = []
    
    private let settingsModel: SettingsModel
    private let eventStore: EventStore
    private let statusModel: AppStatusModel
    private let dateParser: DateParser
    private let breakManager: BreakManager
    private let logger = Logger.shared
    
    private var cancellables: Set<AnyCancellable> = []
    
    // Variables for precision timing
    private var eventTimeToleranceSeconds: TimeInterval = AppConfiguration.eventTimeToleranceSeconds
    
    init(settingsModel: SettingsModel, eventStore: EventStore, statusModel: AppStatusModel, 
         dateParser: DateParser, breakManager: BreakManager) {
        self.settingsModel = settingsModel
        self.eventStore = eventStore
        self.statusModel = statusModel
        self.dateParser = dateParser
        self.breakManager = breakManager
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe changes in refresh interval
        settingsModel.$eventRefreshIntervalMinutes
            .sink { [weak self] newValue in
                guard GoogleOAuthManager.shared.isAuthenticated else { return }
                self?.startRefreshingEvents(every: newValue)
            }
            .store(in: &cancellables)
        
        // Observe changes in authentication status
        GoogleOAuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.fetchAndTrackEvents()
                } else {
                    self?.stopAllTimers()
                    self?.clearEvents()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startScheduling() {
        guard GoogleOAuthManager.shared.isAuthenticated else { return }
        fetchAndTrackEvents()
    }
    
    func stopScheduling() {
        stopAllTimers()
        clearEvents()
    }
    
    func adjustEventTimeTolerance(_ seconds: TimeInterval) {
        eventTimeToleranceSeconds = max(0.1, min(2.0, seconds))
        logger.info("Timing tolerance adjusted to ±\(eventTimeToleranceSeconds)s")
    }
    
    // MARK: - Private Methods
    
    private func startRefreshingEvents(every intervalMinutes: Int) {
        eventRefreshTimer?.invalidate()
        logger.info("Timer: refresh events every \(intervalMinutes) min")
        eventRefreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            self?.fetchAndTrackEvents()
        }
    }
    
    private func startPrecisionTimer() {
        eventPrecisionTimer?.invalidate()
        
        guard !futureEvents.isEmpty else {
            logger.verbose("No future events, precision timer paused")
            return
        }
        
        logger.verbose("Precision timer started (every \(AppConfiguration.precisionTimerInterval) seconds)")
        eventPrecisionTimer = Timer(timeInterval: AppConfiguration.precisionTimerInterval, repeats: true) { [weak self] _ in
            self?.checkNextEventTiming()
        }
        
        RunLoop.main.add(eventPrecisionTimer!, forMode: .common)
    }
    
    private func stopPrecisionTimer() {
        eventPrecisionTimer?.invalidate()
        eventPrecisionTimer = nil
        nextEvent = nil
        logger.verbose("Precision timer stopped")
    }
    
    private func stopAllTimers() {
        eventRefreshTimer?.invalidate()
        eventRefreshTimer = nil
        stopPrecisionTimer()
    }
    
    private func clearEvents() {
        futureEvents = []
        nextEvent = nil
        triggeredEventIDs.removeAll()
    }
    
    private func findNextEvent() -> CalendarEvent? {
        let now = Date()
        
        return futureEvents
            .filter { event in
                guard let startString = event.start.dateTime,
                      let startDate = dateParser.parseDate(from: startString),
                      let _ = event.hangoutLink else { return false }
                
                return startDate > now && !triggeredEventIDs.contains(event.id)
            }
            .sorted { event1, event2 in
                guard let start1 = event1.start.dateTime,
                      let start2 = event2.start.dateTime,
                      let date1 = dateParser.parseDate(from: start1),
                      let date2 = dateParser.parseDate(from: start2) else { return false }
                
                return date1 < date2
            }
            .first
    }
    
    private func checkNextEventTiming() {
        guard !breakManager.isBreakActive else { return }

        // Search for the next event if we don't have one or if the current one has passed
        if nextEvent == nil || hasEventPassed(nextEvent) {
            nextEvent = findNextEvent()
        }
        
        guard let event = nextEvent,
              let startString = event.start.dateTime,
              let startDate = dateParser.parseDate(from: startString) else {
            stopPrecisionTimer()
            return
        }
        
        let now = Date()
        let timeUntilEvent = startDate.timeIntervalSince(now)
        
        // Detailed debug timing
        if timeUntilEvent <= AppConfiguration.debugTimingThreshold && Int(timeUntilEvent * 10) % 10 == 0 {
            let currentFormatter = DateFormatter()
            currentFormatter.dateFormat = "HH:mm:ss.SSS"
            let eventFormatter = DateFormatter()
            eventFormatter.dateFormat = "HH:mm:ss.SSS"
            
            let currentTime = currentFormatter.string(from: now)
            let eventTime = eventFormatter.string(from: startDate)
            
            logger.verbose("Debug timing - Current time: \(currentTime), Event: \(eventTime), Difference: \(String(format: "%.1f", timeUntilEvent))s")
        }

        // Activate overlay with tolerance
        if timeUntilEvent <= eventTimeToleranceSeconds && timeUntilEvent >= -eventTimeToleranceSeconds {
            logger.info("Activating overlay for '\(event.summary ?? "-")' (T-\(String(format: "%.1f", timeUntilEvent))s)")
            triggeredEventIDs.insert(event.id)
            breakManager.startBreak()
            nextEvent = nil
        }
    }
    
    private func hasEventPassed(_ event: CalendarEvent?) -> Bool {
        guard let event = event,
              let startString = event.start.dateTime,
              let startDate = dateParser.parseDate(from: startString) else { return true }
        
        return startDate < Date()
    }
    
    private func fetchAndTrackEvents() {
        GoogleOAuthManager.shared.fetchTodayEvents { [weak self] events in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.logger.info("Events loaded: \(events?.count ?? 0)")
                events?.forEach { self.logger.verbose("• \($0.summary ?? "(no title)")") }
                
                self.eventStore.events = events ?? []
                self.futureEvents = events ?? []
                self.triggeredEventIDs.removeAll()
                
                self.statusModel.lastSyncDate = Date()
                
                self.startPrecisionTimer()
                self.dateParser.debugEventDates(events ?? [])
                self.logUpcomingEvents()
            }
        }
    }
    
    private func logUpcomingEvents() {
        guard !futureEvents.isEmpty else {
            logger.info("No pending events")
            return
        }
        
        if let next = findNextEvent() {
            if let startString = next.start.dateTime,
               let startDate = dateParser.parseDate(from: startString) {
                let timeUntil = startDate.timeIntervalSince(Date())
                logger.info("Next event: '\(next.summary ?? "-")' in \(Int(timeUntil/60)) minutes")
            }
        } else {
            logger.info("No more Meet events for today")
        }
    }
}
