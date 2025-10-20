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
        Task {
            let result = try? await APIClient().health()
            print("HEALTH:", result as Any)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ProjectsListView()
        }
    }
}

