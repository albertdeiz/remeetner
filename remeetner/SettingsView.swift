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

    @State private var events: [CalendarEvent] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Duración del descanso")
                .font(.headline)

            Stepper(value: $settings.breakDuration, in: 5...600, step: 5) {
                Text("\(Int(settings.breakDuration)) segundos")
            }

            Divider()

            Text("Eventos de hoy")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if events.isEmpty {
                Text("No hay eventos.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(events, id: \.id) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.summary ?? "Sin título")
                                    .bold()
                                if let start = event.start.dateTime {
                                    Text(formatTime(from: start))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let link = event.hangoutLink {
                                    Text("🔗 Google Meet")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(height: 200)
            }

            Divider()

            Button("Cerrar") {
                presentation.wrappedValue.dismiss()
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            GoogleOAuthManager.shared.fetchTodayEvents { result in
                DispatchQueue.main.async {
                    self.events = result ?? []
                }
            }
        }
    }

    func formatTime(from iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return iso
    }
}


