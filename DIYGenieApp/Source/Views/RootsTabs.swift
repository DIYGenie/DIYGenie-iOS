import SwiftUI

struct RootTabs: View {
    @State private var selectedTab = 0

    // Projects tab navigation
    @State private var projectsPath = NavigationPath()
    @State private var selectedProject: Project?

    var body: some View {
        TabView(selection: $selectedTab) {

            // HOME
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            // NEW PROJECT
            NavigationStack {
                NewProjectView { project in
                    // When a project is created from the New tab:
                    // 1) Remember it
                    // 2) Switch to Projects tab
                    // 3) Push its detail screen on that tab’s nav stack
                    selectedProject = project
                    projectsPath = NavigationPath()          // reset stack to list
                    projectsPath.append("projectDetail")     // then push detail
                    selectedTab = 2                          // go to Projects tab
                }
            }
            .tabItem {
                Label("New", systemImage: "plus.circle")
            }
            .tag(1)

            // PROJECTS
            NavigationStack(path: $projectsPath) {
                ProjectsListView()
                    .navigationDestination(for: String.self) { route in
                        if route == "projectDetail", let p = selectedProject {
                            ProjectDetailsView(project: p)
                        }
                    }
            }
            .tabItem {
                Label("Projects", systemImage: "hammer")
            }
            .tag(2)

            // PROFILE
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(3)
        }
        .tint(.purple)
    }
}
