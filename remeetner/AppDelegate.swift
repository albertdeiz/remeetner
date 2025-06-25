//
//  AppDelegate.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import SwiftUI
import AppKit

class SettingsModel: ObservableObject {
    @Published var breakDuration: TimeInterval = 10
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var overlayWindow: NSWindow?
    var settingsWindow: NSWindow?

    var settingsModel = SettingsModel()
    var overlayTimer: Timer?
    var secondsRemaining: Int = 0
    
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
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "moon.zzz.fill", accessibilityDescription: "remeetner")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Activar descanso", action: #selector(startBreak), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Conectar Google Calendar", action: #selector(connectGoogleCalendar), keyEquivalent: "g"))
        menu.addItem(NSMenuItem(title: "Configuración...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Salir", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
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

    @objc func startBreak() {
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

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == overlayWindow {
                overlayWindow = nil
            } else if window == settingsWindow {
                settingsWindow = nil
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
