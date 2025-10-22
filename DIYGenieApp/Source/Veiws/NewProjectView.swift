import SwiftUI

struct NewProjectView: View {
    @State private var projectName = ""
    @State private var goal = ""

    var body: some View {
        Form {
            Section {
                TextField("Project Name", text: $projectName)
                TextField("Goal", text: $goal)
                Button("Continue") {}
            }
        }
        .navigationTitle("New Project")
    }
}
