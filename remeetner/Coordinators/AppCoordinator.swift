//
//  AppCoordinator.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import SwiftUI
import AppKit
import Combine

/// Coordinador principal de la aplicación - Punto de entrada único
class AppCoordinator: ObservableObject, AppCoordinating {
    // MARK: - Dependencies
    private let settingsModel: SettingsModel
    private let statusModel: AppStatusModel
    private let eventStore: EventStore
    
    // MARK: - Managers
    private let windowManager: WindowManager
    private let menuBarManager: MenuBarManager
    private let audioManager: AudioManager
    private let dateParser: DateParser
    private let breakManager: BreakManager
    private let eventScheduler: EventScheduler
    
    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        // Initialize models
        self.settingsModel = SettingsModel()
        self.statusModel = AppStatusModel()
        self.eventStore = EventStore()
        
        // Initialize managers
        self.windowManager = WindowManager.shared
        self.menuBarManager = MenuBarManager(statusModel: statusModel)
        self.audioManager = AudioManager()
        self.dateParser = DateParser.shared
        
        // Configure window manager with shared instances
        self.windowManager.configure(settingsModel: settingsModel, eventStore: eventStore, statusModel: statusModel)
        
        // Initialize break manager with dependencies
        self.breakManager = BreakManager(
            settingsModel: settingsModel,
            windowManager: windowManager,
            audioManager: audioManager
        )
        
        // Initialize event scheduler with dependencies
        self.eventScheduler = EventScheduler(
            settingsModel: settingsModel,
            eventStore: eventStore,
            statusModel: statusModel,
            dateParser: dateParser,
            breakManager: breakManager
        )
        
        setupDelegates()
        startScheduling()
    }
    
    private func setupDelegates() {
        menuBarManager.setDelegate(self)
    }
    
    private func startScheduling() {
        eventScheduler.startScheduling()
    }
    
    // MARK: - Public Methods
    
    func handleURLOpen(_ urls: [URL]) {
        for url in urls {
            if GoogleOAuthManager.shared.handleRedirectURL(url) {
                print("OAuth redirect handled.")
                break
            }
        }
    }
    
    func performGoogleAuth() {
        guard let window = NSApp.windows.first else {
            print("No window available for presentation.")
            return
        }
        
        GoogleOAuthManager.shared.startAuthorization(presentingWindow: window) { success in
            print(success ? "✅ Authentication successful." : "❌ Authentication failed.")
        }
    }
}

// MARK: - MenuBarManagerDelegate

extension AppCoordinator: MenuBarManagerDelegate {
    func menuBarManagerDidRequestShowOverlay() {
        breakManager.startBreak()
    }
    
    func menuBarManagerDidRequestShowEvents() {
        windowManager.showEvents()
    }
    
    func menuBarManagerDidRequestShowSettings() {
        windowManager.showSettings()
    }
    
    func menuBarManagerDidRequestLogout() {
        GoogleOAuthManager.shared.clearAuthState()
        eventScheduler.stopScheduling()
    }
    
    func menuBarManagerDidRequestGoogleAuth() {
        performGoogleAuth()
    }
    
    func menuBarManagerDidRequestQuit() {
        NSApp.terminate(nil)
    }
}
