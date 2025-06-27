//
//  MenuBarManager.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import AppKit
import Combine

/// Gestiona el menu bar y status item
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
        
        // Observar cambios en el estado de autenticación
        GoogleOAuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusButton()
                self?.updateMenuItems()
            }
            .store(in: &cancellables)
        
        // Observar cambios en la fecha de última sincronización
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
        
        // Activar descanso
        let breakItem = NSMenuItem(title: "Activar descanso", action: #selector(showOverlayAction), keyEquivalent: "b")
        breakItem.target = self
        menu.addItem(breakItem)
        
        if isAuthenticated {
            // Última sincronización
            if let lastSync = statusModel.lastSyncDate {
                let formatted = DateFormatter.localizedString(from: lastSync, dateStyle: .none, timeStyle: .short)
                menu.addItem(NSMenuItem(title: "Última sincronización: \(formatted)", action: nil, keyEquivalent: ""))
            }
            
            menu.addItem(NSMenuItem.separator())
            
            // Eventos del calendario
            let eventsItem = NSMenuItem(title: "Eventos del calendario", action: #selector(openCalendarEventsAction), keyEquivalent: "e")
            eventsItem.target = self
            menu.addItem(eventsItem)
            
            // Configuración
            let settingsItem = NSMenuItem(title: "Configuración", action: #selector(openSettingsAction), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
            
            // Cerrar sesión
            let logoutItem = NSMenuItem(title: "Cerrar sesión", action: #selector(logoutAction), keyEquivalent: "l")
            logoutItem.target = self
            menu.addItem(logoutItem)
        } else {
            // Conectar Google Calendar
            let connectItem = NSMenuItem(title: "Conectar Google Calendar", action: #selector(connectGoogleCalendarAction), keyEquivalent: "g")
            connectItem.target = self
            menu.addItem(connectItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Salir
        let quitItem = NSMenuItem(title: "Salir", action: #selector(quitAction), keyEquivalent: "q")
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
