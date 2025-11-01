//
//  HomeView.swift
//  DIYGenieApp
//
//  Refined Home screen – cleaner layout, stronger hierarchy & contrast
//

import SwiftUI

struct HomeView: View {
    @State private var projects: [Project] = []
    @State private var isLoading = false
    @State private var userFirstName: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private let templates: [TemplateProject] = [
        .init(title: "Floating Shelves", image: "ShelfPreview"),
        .init(title: "Accent Wall", image: "AccentWallPreview"),
        .init(title: "Mudroom Bench", image: "MudroomBenchPreview")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    colors: [
                        Color(red: 28/255, green: 26/255, blue: 40/255),
                        Color(red: 58/255, green: 35/255, blue: 110/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Welcome Header
                        VStack(alignment: .leading, spacing: 10) {
                            Text(isReturningUser ? "Welcome back, \(userFirstName)" : "Welcome to DIY Genie")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(isReturningUser
                                 ? "Ready to pick up where you left off?"
                                 : "Describe your project or start with a template → Take a photo → Get your custom step-by-step plan.")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.75))
                                .lineSpacing(3)
                            
                            Button {
                                // Navigate to NewProjectView
                            } label: {
                                Text("Start New Project")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(colors: [
                                            Color(red: 155/255, green: 90/255, blue: 255/255),
                                            Color(red: 115/255, green: 73/255, blue: 224/255)
                                        ], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // MARK: - Template Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Not sure where to begin?")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Start with a template.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(templates) { template in
                                        TemplateCard(template: template)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Recent Projects
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Recent Projects")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Pick up where you left off.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else if projects.isEmpty {
                                    VStack(spacing: 10) {
                                        Text("No projects yet — your next idea starts here!")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.8))
                                        Button {
                                            // Navigate to NewProjectView
                                        } label: {
                                            Text("Start New Project")
                                                .font(.system(size: 16, weight: .medium))
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 24)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(12)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 12)
                                } else {
                                    VStack(spacing: 14) {
                                        ForEach(projects.prefix(3)) { project in
                                            ProjectCard(project: project)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .task {
                await loadUserData()
                await loadProjects()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed
    private var isReturningUser: Bool {
        !projects.isEmpty
    }
    
    // MARK: - Data
    private func loadUserData() async {
        if let storedName = UserDefaults.standard.string(forKey: "user_name") {
            userFirstName = storedName.components(separatedBy: " ").first ?? "User"
        } else {
            userFirstName = "User"
        }
    }
    
    private func loadProjects() async {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else { return }
        isLoading = true
        defer { isLoading = false }
        
        let service = ProjectsService(userId: userId)
        do {
            let fetched = try await service.fetchProjects()
            let formatter = ISO8601DateFormatter()
            
            projects = fetched.sorted(by: { (a: Project, b: Project) -> Bool in
                let dateA = formatter.date(from: a.created_at ?? "") ?? Date.distantPast
                let dateB = formatter.date(from: b.created_at ?? "") ?? Date.distantPast
                return dateA > dateB
            })
        } catch {
            print("Error loading projects: \(error)")
        }
    }
}

// MARK: - Template Model & Card
struct TemplateProject: Identifiable {
    let id = UUID()
    let title: String
    let image: String
}

struct TemplateCard: View {
    let template: TemplateProject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(template.image)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 130)
                .clipped()
                .cornerRadius(14)

            Text(template.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Button {
                // navigate to new project view with template prefill
            } label: {
                Text("Create")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(Color(red: 188/255, green: 97/255, blue: 255/255))
            }
        }
        .frame(width: 200)
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

