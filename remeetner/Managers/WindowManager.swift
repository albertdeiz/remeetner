//
//  WindowManager.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import SwiftUI
import AppKit

/// Gestiona todas las ventanas de la aplicación
class WindowManager: NSObject, NSWindowDelegate, WindowManaging {
    static let shared = WindowManager()
    
    private var overlayWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var eventsWindow: NSWindow?
    
    private var settingsModel: SettingsModel!
    private var eventStore: EventStore!
    private var statusModel: AppStatusModel!
    
    override init() {
        super.init()
    }
    
    func configure(settingsModel: SettingsModel, eventStore: EventStore, statusModel: AppStatusModel) {
        self.settingsModel = settingsModel
        self.eventStore = eventStore
        self.statusModel = statusModel
    }
    
    // MARK: - Overlay Window
    
    func showOverlay(duration: TimeInterval, onTap: @escaping () -> Void) {
        guard overlayWindow == nil else { return }
        guard let screenFrame = NSScreen.main?.frame else { return }
        
        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = NSColor.black.withAlphaComponent(AppConfiguration.overlayOpacity)
        overlayWindow?.isOpaque = false
        overlayWindow?.ignoresMouseEvents = false
        overlayWindow?.delegate = self
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow?.makeKeyAndOrderFront(nil)
        
        updateOverlayView(secondsRemaining: Int(duration), totalDuration: Int(duration), onTap: onTap)
    }
    
    func updateOverlayView(secondsRemaining: Int, totalDuration: Int, onTap: @escaping () -> Void) {
        guard let overlayWindow else { return }
        
        let view = OverlayView(
            secondsRemaining: secondsRemaining,
            duration: totalDuration,
            onTap: onTap
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
        DispatchQueue.main.async { [weak self] in
            self?.overlayWindow?.orderOut(nil)
            self?.overlayWindow = nil
        }
    }
    
    var isOverlayVisible: Bool {
        return overlayWindow != nil
    }
    
    // MARK: - Settings Window
    
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(settings: settingsModel)
            let hosting = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: AppConfiguration.settingsWindowSize.width, height: AppConfiguration.settingsWindowSize.height),
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
    
    // MARK: - Events Window
    
    func showEvents() {
        if eventsWindow == nil {
            let eventsView = EventsView()
                .environmentObject(eventStore)
                .environmentObject(statusModel)
            
            let hosting = NSHostingController(rootView: eventsView)
            
            eventsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: AppConfiguration.eventsWindowSize.width, height: AppConfiguration.eventsWindowSize.height),
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
    
    // MARK: - NSWindowDelegate
    
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
}
