//
//  SettingsView.swift
//  remeetner
//
//  Created by Alberto Diaz on 24-06-25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @Environment(\.presentationMode) var presentation

    var body: some View {
        VStack(spacing: 20) {
            Text("Break duration")
                .font(.headline)

            Stepper(value: $settings.breakDuration, in: 5...600, step: 5) {
                Text("\(Int(settings.breakDuration)) seconds")
            }

            Divider()

            Text("Sync interval")
                .font(.headline)

            Stepper(value: $settings.eventRefreshIntervalMinutes, in: 1...60, step: 1) {
                Text("Every \(settings.eventRefreshIntervalMinutes) min")
            }

            Divider()

            Button("Close") {
                presentation.wrappedValue.dismiss()
            }
        }
        .padding()
        .frame(width: 300)
    }
}
