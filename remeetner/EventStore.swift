//
//  EventStore.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation
import Combine

class EventStore: ObservableObject {
    @Published var events: [CalendarEvent] = []
}
