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
            let client = APIClient(baseURL: URL(string: "https://api.diygenieapp.com")!)
            let result = try? await client.health()
            print("HEALTH:", result as Any)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ProjectsListView()
        }
    }
}

