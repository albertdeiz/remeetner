//
//  remeetnerApp.swift
//  remeetner
//
//  Created by Alberto Diaz on 24-06-25.
//

import SwiftUI
import AppKit

@main
struct remeetnerApp: App {
    // Conectar AppDelegate con SwiftUI
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No necesitamos ventana principal visible
        Settings {
            EmptyView()
        }
    }
}
