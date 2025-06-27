//
//  SettingsModel.swift
//  remeetner
//
//  Created by Alberto Diaz on 26-06-25.
//

import Foundation
import Combine

class SettingsModel: ObservableObject {
    @Published var breakDuration: TimeInterval = 10
    @Published var eventRefreshIntervalMinutes: Int = 5
}
