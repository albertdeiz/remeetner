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
    // Connect AppDelegate with SwiftUI
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We don't need a main visible window
        Settings {
            EmptyView()
        }
    }
}
