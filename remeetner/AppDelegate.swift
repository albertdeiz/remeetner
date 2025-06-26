//
//  AppDelegate.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import SwiftUI
import AppKit
import Combine

class SettingsModel: ObservableObject {
    @Published var breakDuration: TimeInterval = 10
    @Published var minutesBeforeMeet: Int = 2
    @Published var eventCheckIntervalMinutes: Int = 1
    @Published var eventRefreshIntervalMinutes: Int = 5
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var overlayWindow: NSWindow?
    var settingsWindow: NSWindow?
    var eventsWindow: NSWindow?
    
    var cancellables: Set<AnyCancellable> = []

    var settingsModel = SettingsModel()
    var overlayTimer: Timer?
    var secondsRemaining: Int = 0
    
    var eventCheckTimer: Timer?
    var eventRefreshTimer: Timer?
    var futureEvents: [CalendarEvent] = []
    
    let eventStore = EventStore()
    
    func application(_ app: NSApplication, open urls: [URL]) {
        for url in urls {
            if GoogleOAuthManager.shared.handleRedirectURL(url) {
                print("OAuth redirect handled.")
                break
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        statusItem.menu = menu
        
        updateStatusButton()
        updateMenuItems()

        GoogleOAuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                self?.updateMenuItems()
                self?.updateStatusButton()
                
                if isAuthenticated {
                    self?.fetchAndTrackEvents()
                } else {
                    self?.eventCheckTimer?.invalidate()
                    self?.futureEvents = []
                }
            }
            .store(in: &cancellables)
    }
    
    @objc func connectGoogleCalendar() {
        guard let window = NSApp.windows.first else {
            print("No window available for presentation.")
            return
        }

        GoogleOAuthManager.shared.startAuthorization(presentingWindow: window) { success in
            if success {
                print("Autenticación exitosa.")
            } else {
                print("Falló la autenticación.")
            }
        }
    }

    @objc func showOverlay() {
        guard overlayWindow == nil else { return }
        guard let screenFrame = NSScreen.main?.frame else { return }

        secondsRemaining = Int(settingsModel.breakDuration)
        playStartSound()

        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = NSColor.black.withAlphaComponent(0.6)
        overlayWindow?.isOpaque = false
        overlayWindow?.ignoresMouseEvents = false
        overlayWindow?.delegate = self
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow?.makeKeyAndOrderFront(nil)

        updateOverlayView()

        overlayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }

            if self.secondsRemaining > 1 {
                self.secondsRemaining -= 1
                self.updateOverlayView()
            } else {
                self.hideOverlay()
            }
        }
    }
    
    func updateStatusButton() {
        guard let button = statusItem.button else { return }

        let isAuthenticated = GoogleOAuthManager.shared.isAuthenticated

        button.image = NSImage(systemSymbolName: isAuthenticated ? "checkmark.circle.fill" : "moon.zzz.fill", accessibilityDescription: "remeetner")
    }
    
    func updateMenuItems() {
        let isAuthenticated = GoogleOAuthManager.shared.isAuthenticated
        guard let menu = statusItem.menu else { return }

        menu.removeAllItems()
        
        menu.addItem(NSMenuItem(title: "Activar descanso", action: #selector(showOverlay), keyEquivalent: "b"))

        if isAuthenticated {
            menu.addItem(NSMenuItem(title: "Eventos del calendario", action: #selector(openCalendarEvents), keyEquivalent: "e"))
            menu.addItem(NSMenuItem(title: "Configuración", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem(title: "Cerrar sesión", action: #selector(logout), keyEquivalent: "l"))
        } else {
            menu.addItem(NSMenuItem(title: "Conectar Google Calendar", action: #selector(connectGoogleCalendar), keyEquivalent: "g"))
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Salir", action: #selector(quit), keyEquivalent: "q"))
    }

    func updateOverlayView() {
        guard let overlayWindow = overlayWindow else { return }

        let view = OverlayView(
            secondsRemaining: secondsRemaining,
            duration: Int(settingsModel.breakDuration),
            onTap: { self.hideOverlay() }
        )

        if let hosting = overlayWindow.contentViewController as? NSHostingController<OverlayView> {
            hosting.rootView = view
        } else {
            let hosting = NSHostingController(rootView: view)
            hosting.view.frame = overlayWindow.contentView?.bounds ?? .zero
            overlayWindow.contentViewController = hosting
        }
    }

    func hideOverlay() {
        DispatchQueue.main.async {
            self.playEndSound()
            self.overlayTimer?.invalidate()
            self.overlayTimer = nil
            self.overlayWindow?.orderOut(nil)
            self.overlayWindow = nil
        }
    }
    
    @objc func logout() {
        GoogleOAuthManager.shared.clearAuthState()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(settings: settingsModel)
            let hosting = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.contentViewController = hosting
            settingsWindow?.title = "Configuración"
            settingsWindow?.center()
            settingsWindow?.makeKeyAndOrderFront(nil)
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.delegate = self
        } else {
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func openCalendarEvents() {
        if eventsWindow == nil {
            let eventsView = EventsView()
                .environmentObject(eventStore)

            let hosting = NSHostingController(rootView: eventsView)

            eventsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            eventsWindow?.contentViewController = hosting
            eventsWindow?.title = "Eventos del calendario"
            eventsWindow?.center()
            eventsWindow?.makeKeyAndOrderFront(nil)
            eventsWindow?.isReleasedWhenClosed = false
            eventsWindow?.delegate = self
        } else {
            eventsWindow?.makeKeyAndOrderFront(nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == overlayWindow {
                overlayWindow = nil
            } else if window == eventsWindow {
                eventsWindow = nil
            } else if window == settingsWindow {
                settingsWindow = nil
            }
        }
    }
    
    func startRefreshingEvents(every intervalMinutes: Int) {
        eventRefreshTimer?.invalidate()
        eventRefreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            print("🔁 Refrescando eventos desde Google Calendar...")
            self?.fetchAndTrackEvents()
        }
    }
    
    func startCheckingForUpcomingMeetEvents(every intervalMinutes: Int) {
        eventCheckTimer?.invalidate()
        eventCheckTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            guard let self else { return }

            GoogleOAuthManager.shared.fetchTodayEvents { events in
                DispatchQueue.main.async {
                    print("🔁 Eventos actualizados:", events?.count ?? 0)
                    self.eventStore.events = events ?? []
                    self.futureEvents = events ?? []
                    self.checkUpcomingEvents()
                }
            }
        }
    }

    func checkUpcomingEvents() {
        guard overlayWindow == nil else { return }

        let now = Date()
        let leadTime = settingsModel.minutesBeforeMeet * 60

        for event in futureEvents {
            guard let startString = event.start.dateTime,
                  let startDate = ISO8601DateFormatter().date(from: startString),
                  let _ = event.hangoutLink else { continue }

            let timeUntilStart = startDate.timeIntervalSince(now)

            if timeUntilStart > 0 && timeUntilStart <= TimeInterval(leadTime) {
                print("Iniciando descanso para Meet que comienza en \(Int(timeUntilStart)) segundos")
                showOverlay()
                break
            }
        }
    }
    
    func fetchAndTrackEvents() {
        GoogleOAuthManager.shared.fetchTodayEvents { [weak self] events in
            DispatchQueue.main.async {
                print("Eventos cargados:", events?.count ?? 0)
                events?.forEach { print("•", $0.summary ?? "(sin título)") }
                
                self?.eventStore.events = events ?? []
                self?.futureEvents = events ?? []
                self?.startCheckingForUpcomingMeetEvents(every: self?.settingsModel.eventCheckIntervalMinutes ?? 1)
                self?.startRefreshingEvents(every: self?.settingsModel.eventRefreshIntervalMinutes ?? 5)
            }
        }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func playStartSound() {
        NSSound(named: "Glass")?.play()
    }

    func playEndSound() {
        NSSound(named: "Ping")?.play()
    }
}
