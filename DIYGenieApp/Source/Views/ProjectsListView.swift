import SwiftUI

struct ProjectsListView: View {
    // MARK: - State
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var userId: String = UserDefaults.standard.string(forKey: "user_id") ?? ""
    
    // MARK: - Services
    private let projectsService: ProjectsService
    
    // MARK: - Gradient Colors
    private let gradientTop = Color(red: 28/255, green: 26/255, blue: 40/255)
    private let gradientBottom = Color(red: 58/255, green: 35/255, blue: 110/255)
    private let accentStart = Color(red: 115/255, green: 73/255, blue: 224/255)
    private let accentEnd = Color(red: 146/255, green: 86/255, blue: 255/255)
    
    // MARK: - Init
    init() {
        projectsService = ProjectsService(userId: UserDefaults.standard.string(forKey: "user_id") ?? "")
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [gradientTop, gradientBottom],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading your DIY projects...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.white)
                } else if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Your Projects")
            .onAppear(perform: loadProjects)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No projects yet — your next idea starts here!")
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: NewProjectView()) {
                Text("Start New Project")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [accentStart, accentEnd],
                                               startPoint: .leading,
                                               endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Project List
    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(projects) { project in
                    NavigationLink(destination: ProjectDetailsView(project: project)) {
                        ProjectCard(project: project)
                            .padding(.horizontal)
                            .transition(.scale)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func loadProjects() {
        isLoading = true
        
        Task {
            do {
                let fetchedProjects = try await projectsService.fetchProjects()
                DispatchQueue.main.async {
                    self.projects = fetchedProjects
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Error loading projects: \(error.localizedDescription)"
                }
            }
        }
    }
}
