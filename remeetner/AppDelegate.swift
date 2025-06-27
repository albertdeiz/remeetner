//
//  AppDelegate.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var appCoordinator: AppCoordinator!

    func application(_ app: NSApplication, open urls: [URL]) {
        appCoordinator.handleURLOpen(urls)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        appCoordinator = AppCoordinator()
    }
}
