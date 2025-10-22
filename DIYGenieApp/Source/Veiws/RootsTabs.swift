import SwiftUI

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
            NavigationStack { NewProjectView() }
                .tabItem { Label("New", systemImage: "plus.circle") }
            NavigationStack { ProjectDetailsView() }
                .tabItem { Label("Projects", systemImage: "hammer") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.purple)
    }
}
