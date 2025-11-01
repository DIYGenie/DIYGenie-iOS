//
//  HomeView.swift
//  DIYGenieApp
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
                LinearGradient(
                    colors: [
                        Color(red: 28/255, green: 26/255, blue: 40/255),
                        Color(red: 58/255, green: 35/255, blue: 110/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // MARK: - Hero Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text(isReturningUser ? "Welcome back, \(userFirstName)" : "Welcome to DIY Genie")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text(
                                isReturningUser
                                ? "Ready to pick up where you left off?"
                                : "Describe your project or start with a template → Take a photo → Get your custom step-by-step plan."
                            )
                            .foregroundColor(.white.opacity(0.75))
                            .font(.system(size: 16))
                            .lineSpacing(4)

                            HStack(spacing: 14) {
                                NavigationLink(destination: NewProjectView()) {
                                    Text("Start New Project")
                                        .font(.system(size: 17, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 115/255, green: 73/255, blue: 224/255),
                                                    Color(red: 146/255, green: 86/255, blue: 255/255)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                }

                                if isReturningUser {
                                    NavigationLink(destination: ProjectsListView()) {
                                        Text("View My Projects")
                                            .font(.system(size: 17, weight: .medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 15)
                                            .background(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(14)
                                    }
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                        // MARK: - Template Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Not sure where to begin?")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Start with a template.")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 15))

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

                        // MARK: - Recent Projects Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Recent Projects")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Pick up where you left off.")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 15))

                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if projects.isEmpty {
                                VStack(spacing: 10) {
                                    Text("No projects yet — your next idea starts here!")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 15))
                                    NavigationLink(destination: NewProjectView()) {
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

    // MARK: - Computed Props
    private var isReturningUser: Bool {
        !projects.isEmpty
    }

    // MARK: - Data Loading
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

            projects = fetched.sorted { a, b in
                let dateA = formatter.date(from: a.createdAt) ?? Date.distantPast
                let dateB = formatter.date(from: b.createdAt) ?? Date.distantPast
                return dateA > dateB
            }
        } catch {
            print("🔴 Error loading projects:", error)
        }
    }
}

// MARK: - Template Model
struct TemplateProject: Identifiable {
    let id = UUID()
    let title: String
    let image: String
}

// MARK: - Template Card
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

            NavigationLink(destination: NewProjectView()) {
                Text("Create")
                    .font(.system(size: 15, weight: .medium))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .frame(width: 200)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
