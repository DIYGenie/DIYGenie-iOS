import SwiftUI
import Foundation

struct ProjectDetailView: View {
    let project: Project

    @State private var latestStatus: String = ""
    @State private var isWorking: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        List {
            Section(header: Text("Info")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(project.name ?? String(describing: project))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Goal")
                    Spacer()
                    Text(project.goal ?? String(describing: project))
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text("Preview")) {
                Text("Status: \(latestStatus.isEmpty ? "unknown" : latestStatus)")
            }
        }
        .navigationTitle("Project Detail")
        .toolbar {
            Button("Refresh Plan") {
                Task {
                    isWorking = true
                    errorMessage = nil
                    do {
                        let plan = try await APIClient.shared.fetchPlan(projectId: project.idAsUUID())
                        print("Plan counts:", plan.steps.count, plan.tools.count, plan.materials.count)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isWorking = false
                }
            }
        }
        .onAppear {
            Task {
                do {
                    let preview = try await APIClient.shared.requestPreview(projectId: project.idAsUUID())
                    latestStatus = preview.status
                } catch {
                    latestStatus = ""
                }
            }
        }
    }
}

#if DEBUG
struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        if let dummyProject = try? Project(id: UUID(), name: "Sample Project", goal: "Learn SwiftUI") {
            NavigationView {
                ProjectDetailView(project: dummyProject)
            }
        } else {
            Text("No preview available")
        }
    }
}
#endif
