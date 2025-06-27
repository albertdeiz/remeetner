//
//  AppStatusModel.swift
//  remeetner
//
//  Created by Alberto Diaz on 26-06-25.
//

import Foundation
import Combine

class AppStatusModel: ObservableObject {
    @Published var lastSyncDate: Date?
}
