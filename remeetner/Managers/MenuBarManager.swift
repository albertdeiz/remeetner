//
//  MenuBarManager.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import AppKit
import Combine

/// Manages the menu bar and status item
class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []
    
    private let statusModel: AppStatusModel
    private weak var delegate: MenuBarManagerDelegate?
    
    init(statusModel: AppStatusModel) {
        self.statusModel = statusModel
        setupStatusItem()
    }
    
    func setDelegate(_ delegate: MenuBarManagerDelegate) {
        self.delegate = delegate
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.menu = NSMenu()

        // Observe changes in authentication status
        GoogleOAuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusButton()
                self?.updateMenuItems()
            }
            .store(in: &cancellables)

        // Observe changes in last sync date
        statusModel.$lastSyncDate
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuItems()
            }
            .store(in: &cancellables)
        
        updateStatusButton()
        updateMenuItems()
    }
    
    private func updateStatusButton() {
        guard let button = statusItem?.button else { return }
        let isAuthenticated = GoogleOAuthManager.shared.isAuthenticated
        button.image = NSImage(
            systemSymbolName: isAuthenticated ? "checkmark.circle.fill" : "moon.zzz.fill",
            accessibilityDescription: "remeetner"
        )
    }
    
    private func updateMenuItems() {
        let isAuthenticated = GoogleOAuthManager.shared.isAuthenticated
        guard let menu = statusItem?.menu else { return }
        
        menu.removeAllItems()
        
        // Activate break
        let breakItem = NSMenuItem(title: "Activate break", action: #selector(showOverlayAction), keyEquivalent: "b")
        breakItem.target = self
        menu.addItem(breakItem)
        
        if isAuthenticated {
            // Last sync
            if let lastSync = statusModel.lastSyncDate {
                let formatted = DateFormatter.localizedString(from: lastSync, dateStyle: .none, timeStyle: .short)
                menu.addItem(NSMenuItem(title: "Last sync: \(formatted)", action: nil, keyEquivalent: ""))
            }
            
            menu.addItem(NSMenuItem.separator())
            
            // Calendar events
            let eventsItem = NSMenuItem(title: "Calendar events", action: #selector(openCalendarEventsAction), keyEquivalent: "e")
            eventsItem.target = self
            menu.addItem(eventsItem)
            
            // Settings
            let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettingsAction), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
            
            // Sign out
            let logoutItem = NSMenuItem(title: "Sign out", action: #selector(logoutAction), keyEquivalent: "l")
            logoutItem.target = self
            menu.addItem(logoutItem)
        } else {
            // Connect Google Calendar
            let connectItem = NSMenuItem(title: "Connect Google Calendar", action: #selector(connectGoogleCalendarAction), keyEquivalent: "g")
            connectItem.target = self
            menu.addItem(connectItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func showOverlayAction() {
        delegate?.menuBarManagerDidRequestShowOverlay()
    }
    
    @objc private func openCalendarEventsAction() {
        delegate?.menuBarManagerDidRequestShowEvents()
    }
    
    @objc private func openSettingsAction() {
        delegate?.menuBarManagerDidRequestShowSettings()
    }
    
    @objc private func logoutAction() {
        delegate?.menuBarManagerDidRequestLogout()
    }
    
    @objc private func connectGoogleCalendarAction() {
        delegate?.menuBarManagerDidRequestGoogleAuth()
    }
    
    @objc private func quitAction() {
        delegate?.menuBarManagerDidRequestQuit()
    }
}

// MARK: - MenuBarManagerDelegate

protocol MenuBarManagerDelegate: AnyObject {
    func menuBarManagerDidRequestShowOverlay()
    func menuBarManagerDidRequestShowEvents()
    func menuBarManagerDidRequestShowSettings()
    func menuBarManagerDidRequestLogout()
    func menuBarManagerDidRequestGoogleAuth()
    func menuBarManagerDidRequestQuit()
}
