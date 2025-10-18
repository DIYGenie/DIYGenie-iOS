//
//  ContentView.swift
//  DIYGenie
//
//  Created by Tye  Kowalski on 10/18/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("ContentView").font(.title)
                NavigationLink("Go to Projects", destination: ProjectsListView())
            }
            .padding()
        }
    }
}

#Preview { ContentView() }

