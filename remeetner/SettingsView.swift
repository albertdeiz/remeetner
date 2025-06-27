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
            Text("Duración del descanso")
                .font(.headline)

            Stepper(value: $settings.breakDuration, in: 5...600, step: 5) {
                Text("\(Int(settings.breakDuration)) segundos")
            }

            Divider()

            Text("Intervalo de verificación")
                .font(.headline)

            Stepper(value: $settings.eventCheckIntervalMinutes, in: 1...30, step: 1) {
                Text("Cada \(settings.eventCheckIntervalMinutes) min (verificar eventos cercanos)")
            }

            Divider()

            Text("Intervalo de actualización")
                .font(.headline)

            Stepper(value: $settings.eventRefreshIntervalMinutes, in: 1...60, step: 1) {
                Text("Cada \(settings.eventRefreshIntervalMinutes) min (sincronizar con Google)")
            }

            Divider()

            Button("Cerrar") {
                presentation.wrappedValue.dismiss()
            }
        }
        .padding()
        .frame(width: 300)
    }
}
