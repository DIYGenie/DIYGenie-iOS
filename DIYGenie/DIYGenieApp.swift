//
//  DIYGenieApp.swift
//  DIYGenie
//
//  Created by Tye  Kowalski on 10/18/25.
//

import SwiftUI

@main
struct DIYGenieApp: App {
    init() {
        _ = UserSession.shared.userId
    }
    
    var body: some Scene {
        WindowGroup {
            ProjectsListView()
        }
    }
}

