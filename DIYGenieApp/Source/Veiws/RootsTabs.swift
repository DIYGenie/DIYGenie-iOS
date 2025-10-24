import SwiftUI

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
            
            // New project tab – our new view doesn’t take an onCreated closure
            NavigationStack { NewProjectView() }
                .tabItem { Label("New", systemImage: "plus.circle") }
            
            // Projects tab – show a list of projects, not the detail view directly
            NavigationStack { ProjectsListView() }
                .tabItem { Label("Projects", systemImage: "hammer") }
            
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.purple)
    }
}
