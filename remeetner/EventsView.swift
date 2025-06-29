//
//  EventsView.swift
//  remeetner
//
//  Created by Alberto Diaz on 24-06-25.
//

import SwiftUI

struct EventsView: View {
    @Environment(\.presentationMode) var presentation

    @EnvironmentObject var eventStore: EventStore
    
    @EnvironmentObject var status: AppStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's events")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if eventStore.events.isEmpty {
                Text("No events.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(eventStore.events, id: \.id) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.summary ?? "No title")
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
                .frame(height: 300)
            }

            Divider()

            Button("Close") {
                presentation.wrappedValue.dismiss()
            }
            
            Divider()
            
            Text("Last sync: \(status.lastSyncDate?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
        }
        .padding()
        .frame(width: 300)
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


