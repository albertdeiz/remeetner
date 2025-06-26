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

            Text("Minutos antes del Meet")
                .font(.headline)

            Stepper(value: $settings.minutesBeforeMeet, in: 1...30, step: 1) {
                Text("\(settings.minutesBeforeMeet) min antes")
            }

            Button("Cerrar") {
                presentation.wrappedValue.dismiss()
            }
        }
        .padding()
        .frame(width: 300)
    }
}
