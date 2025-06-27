//
//  AppDelegate.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var overlayWindow: NSWindow?
    var settingsWindow: NSWindow?
    var eventsWindow: NSWindow?

    var cancellables: Set<AnyCancellable> = []

    var settingsModel = SettingsModel()
    var statusModel = AppStatusModel()

    var overlayTimer: Timer?
    var secondsRemaining: Int = 0

    var eventRefreshTimer: Timer?
    var eventPrecisionTimer: Timer? // Timer para verificar próximo evento cada segundo
    var futureEvents: [CalendarEvent] = []
    var triggeredEventIDs: Set<String> = []

    // Variable para trackear el próximo evento
    var nextEvent: CalendarEvent?
    
    // Variables para precisión de timing
    private var lastCheckTime: Date = Date()
    private var eventTimeToleranceSeconds: TimeInterval = 0.5

    let eventStore = EventStore()
    
    // Formatters configurados para manejar correctamente las fechas de Google Calendar
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
    
    // Función para parsear fecha con múltiples intentos
    private func parseDate(from dateString: String) -> Date? {
        // Intentar con cada formatter
        for (index, formatter) in dateFormatters.enumerated() {
            if let date = formatter.date(from: dateString) {
                // Solo imprimir en debug si es necesario
                if dateString.contains("debug") {
                    print("✅ Fecha parseada con formatter \(index + 1)")
                }
                return date
            }
        }
        
        // Si ninguno funciona, intentar con DateFormatter como último recurso
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = fallbackFormatter.date(from: dateString) {
            print("✅ Fecha parseada con DateFormatter fallback (formato Z)")
            return date
        }
        
        // Intentar sin zona horaria
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = fallbackFormatter.date(from: dateString) {
            print("✅ Fecha parseada con DateFormatter fallback (sin zona horaria)")
            return date
        }
        
        // Último intento: formato más básico
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fallbackFormatter.date(from: dateString)
    }

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
        statusItem.menu = NSMenu()

        updateStatusButton()
        updateMenuItems()

        settingsModel.$eventRefreshIntervalMinutes
            .sink { [weak self] newValue in
                guard GoogleOAuthManager.shared.isAuthenticated else { return }
                self?.startRefreshingEvents(every: newValue)
            }
            .store(in: &cancellables)

        GoogleOAuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                self?.updateMenuItems()
                self?.updateStatusButton()

                if isAuthenticated {
                    self?.fetchAndTrackEvents()
                } else {
                    self?.eventRefreshTimer?.invalidate()
                    self?.eventPrecisionTimer?.invalidate()
                    self?.futureEvents = []
                    self?.nextEvent = nil
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
            print(success ? "✅ Autenticación exitosa." : "❌ Falló la autenticación.")
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
            if let last = statusModel.lastSyncDate {
                let formatted = DateFormatter.localizedString(from: last, dateStyle: .none, timeStyle: .short)
                menu.addItem(NSMenuItem(title: "Última sincronización: \(formatted)", action: nil, keyEquivalent: ""))
            }

            menu.addItem(NSMenuItem.separator())
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
        guard let overlayWindow else { return }

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
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 250),
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
                .environmentObject(statusModel)

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
            if window == overlayWindow { overlayWindow = nil }
            else if window == eventsWindow { eventsWindow = nil }
            else if window == settingsWindow { settingsWindow = nil }
        }
    }

    func startRefreshingEvents(every intervalMinutes: Int) {
        eventRefreshTimer?.invalidate()
        print("🔁 Timer: refresco de eventos cada \(intervalMinutes) min")
        eventRefreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            self?.fetchAndTrackEvents()
        }
    }

    func startPrecisionTimer() {
        eventPrecisionTimer?.invalidate()

        // Solo iniciar si hay eventos futuros
        guard !futureEvents.isEmpty else {
            print("⏱️ No hay eventos futuros, timer de precisión pausado")
            return
        }

        print("⏱️ Timer de precisión iniciado (cada 0.1 segundos)")
        eventPrecisionTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkNextEventTiming()
        }
        
        // Agregar al RunLoop con alta prioridad para máxima precisión
        RunLoop.main.add(eventPrecisionTimer!, forMode: .common)
    }

    func stopPrecisionTimer() {
        eventPrecisionTimer?.invalidate()
        eventPrecisionTimer = nil
        nextEvent = nil
        print("⏱️ Timer de precisión detenido")
    }

    func findNextEvent() -> CalendarEvent? {
        let now = Date()

        return futureEvents
            .filter { event in
                // Solo eventos con enlace de Meet/Hangouts
                guard let startString = event.start.dateTime,
                      let startDate = parseDate(from: startString),
                      let _ = event.hangoutLink else { return false }

                // Solo eventos futuros que no han sido activados
                return startDate > now && !triggeredEventIDs.contains(event.id)
            }
            .sorted { event1, event2 in
                // Ordenar por fecha de inicio
                guard let start1 = event1.start.dateTime,
                      let start2 = event2.start.dateTime,
                      let date1 = parseDate(from: start1),
                      let date2 = parseDate(from: start2) else { return false }

                return date1 < date2
            }
            .first
    }

    func checkNextEventTiming() {
        guard overlayWindow == nil else { return }

        // Buscar el próximo evento si no tenemos uno o si el actual ya pasó
        if nextEvent == nil || hasEventPassed(nextEvent) {
            nextEvent = findNextEvent()
        }

        guard let event = nextEvent,
              let startString = event.start.dateTime,
              let startDate = parseDate(from: startString) else {
            // No hay próximo evento, detener timer de precisión
            stopPrecisionTimer()
            return
        }

        let now = Date()
        let timeUntilEvent = startDate.timeIntervalSince(now)
        
        // Debug: Mostrar timing detallado con milisegundos
        let currentFormatter = DateFormatter()
        currentFormatter.dateFormat = "HH:mm:ss.SSS"
        let eventFormatter = DateFormatter()
        eventFormatter.dateFormat = "HH:mm:ss.SSS"
        
        let currentTime = currentFormatter.string(from: now)
        let eventTime = eventFormatter.string(from: startDate)
        
        // Solo imprimir cada segundo cuando faltan menos de 10 segundos
        if timeUntilEvent <= 10 && Int(timeUntilEvent * 10) % 10 == 0 {
            print("🕐 Debug timing - Actual: \(currentTime), Evento: \(eventTime), Diferencia: \(String(format: "%.1f", timeUntilEvent))s")
        }

        // Activar overlay con tolerancia inteligente
        // Si estamos dentro del rango de tolerancia del evento
        if timeUntilEvent <= eventTimeToleranceSeconds && timeUntilEvent >= -eventTimeToleranceSeconds {
            print("✅ Activando overlay para '\(event.summary ?? "-")' (T-\(String(format: "%.1f", timeUntilEvent))s)")
            print("🕐 Tiempo actual: \(currentTime), Tiempo evento: \(eventTime)")
            print("🎯 Activación con tolerancia de ±\(eventTimeToleranceSeconds)s")
            triggeredEventIDs.insert(event.id)
            showOverlay()

            // Marcar como procesado y buscar siguiente
            nextEvent = nil
        }
    }

    func hasEventPassed(_ event: CalendarEvent?) -> Bool {
        guard let event = event,
              let startString = event.start.dateTime,
              let startDate = parseDate(from: startString) else { return true }

        return startDate < Date()
    }

    func fetchAndTrackEvents() {
        GoogleOAuthManager.shared.fetchTodayEvents { [weak self] events in
            DispatchQueue.main.async {
                print("📆 Eventos cargados:", events?.count ?? 0)
                events?.forEach { print("•", $0.summary ?? "(sin título)") }

                self?.eventStore.events = events ?? []
                self?.futureEvents = events ?? []
                self?.triggeredEventIDs.removeAll()

                self?.statusModel.lastSyncDate = Date()
                
                // Iniciar o reiniciar el timer de precisión
                self?.startPrecisionTimer()
                
                // Debug: Imprimir formatos de fecha para diagnóstico
                self?.debugEventDates(events ?? [])
                
                // Mostrar información sobre próximos eventos
                self?.logUpcomingEvents()
            }
        }
    }

    func debugEventDates(_ events: [CalendarEvent]) {
        print("🔍 === DEBUG: Formatos de fecha de eventos ===")
        for event in events.prefix(3) { // Solo los primeros 3 para no saturar
            if let dateTimeString = event.start.dateTime {
                print("📅 Evento: '\(event.summary ?? "-")'")
                print("   📝 String original: '\(dateTimeString)'")
                
                if let parsedDate = parseDate(from: dateTimeString) {
                    let debugFormatter = DateFormatter()
                    debugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
                    print("   ✅ Fecha parseada: \(debugFormatter.string(from: parsedDate))")
                    
                    let timeInterval = parsedDate.timeIntervalSince(Date())
                    print("   ⏱️ Diferencia con ahora: \(Int(timeInterval)) segundos")
                } else {
                    print("   ❌ ERROR: No se pudo parsear la fecha")
                    print("   🔍 Probando diferentes formatos...")
                    
                    // Mostrar qué formatos intentamos
                    for (index, formatter) in dateFormatters.enumerated() {
                        print("   📝 Formato \(index + 1): \(formatter.formatOptions)")
                    }
                }
                print("")
            }
        }
        print("🔍 === FIN DEBUG ===")
    }

    func logUpcomingEvents() {
        guard !futureEvents.isEmpty else { 
            print("📭 No hay eventos pendientes")
            return 
        }
        
        if let next = findNextEvent() {
            if let startString = next.start.dateTime,
               let startDate = parseDate(from: startString) {
                let timeUntil = startDate.timeIntervalSince(Date())
                print("📅 Próximo evento: '\(next.summary ?? "-")' en \(Int(timeUntil/60)) minutos")
            }
        } else {
            print("📭 No hay más eventos con Meet para hoy")
        }
    }
    
    // Función para ajustar la tolerancia de timing si es necesario
    func adjustEventTimeTolerance(_ seconds: TimeInterval) {
        eventTimeToleranceSeconds = max(0.1, min(2.0, seconds)) // Entre 0.1 y 2 segundos
        print("⚙️ Tolerancia de timing ajustada a ±\(eventTimeToleranceSeconds)s")
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
