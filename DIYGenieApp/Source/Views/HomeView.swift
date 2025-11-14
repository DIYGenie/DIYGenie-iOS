import SwiftUI

//
//  HomeView.swift
//  DIYGenieApp
//
//  Refined Home screen – cleaner layout, stronger hierarchy & contrast
//

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
                // MARK: - Background (DIY Genie brand)
                LinearGradient(
                    gradient: Gradient(colors: [.BgStart, .BgEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // MARK: - Welcome Header
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DIY GENIE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.TextSecondary)
                                .kerning(1.2)

                            Text(isReturningUser ? "Welcome back, \(userFirstName)" : "Welcome to DIY Genie")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.TextPrimary)

                            Text("Start a new DIY plan or pick up where you left off.")
                                .font(.system(size: 15))
                                .foregroundColor(.TextSecondary)
                                .lineSpacing(3)

                            NavigationLink(destination: NewProjectView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Start New Project")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.Accent)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // MARK: - How It Works (4 cards with icons)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How it works")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.TextPrimary)

                            HStack(alignment: .top, spacing: 12) {
                                ProcessStepCard(
                                    step: "1",
                                    title: "Describe",
                                    systemImage: "text.bubble",
                                    subtitle: "Tell Genie what you want to build."
                                )
                                ProcessStepCard(
                                    step: "2",
                                    title: "Add photo",
                                    systemImage: "photo.on.rectangle",
                                    subtitle: "Take or upload a photo of your space."
                                )
                                ProcessStepCard(
                                    step: "3",
                                    title: "Measure",
                                    systemImage: "ruler",
                                    subtitle: "Measure with phone camera."
                                )
                                ProcessStepCard(
                                    step: "4",
                                    title: "Get plan",
                                    systemImage: "hammer",
                                    subtitle: "See your preview + full DIY plan."
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Templates
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Templates")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.TextPrimary)

                            Text("Start faster with a pre-built project and customize it to your space.")
                                .font(.system(size: 14))
                                .foregroundColor(.TextSecondary)

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
                            Text("Your recent projects")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.TextPrimary)

                            Text("Pick up where you left off.")
                                .font(.system(size: 14))
                                .foregroundColor(.TextSecondary)

                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .Accent))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else if projects.isEmpty {
                                    VStack(spacing: 10) {
                                        Text("No projects yet — your next idea starts here.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.TextSecondary)
                                        NavigationLink(destination: NewProjectView()) {
                                            Text("Start New Project")
                                                .font(.system(size: 15, weight: .medium))
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 22)
                                                .background(Color.Surface.opacity(0.7))
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

            // Sort by newest first
            projects = fetched.sorted(by: { (a: Project, b: Project) -> Bool in
                let dateA = formatter.date(from: a.createdAt ?? "") ?? .distantPast
                let dateB = formatter.date(from: b.createdAt ?? "") ?? .distantPast
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
                .foregroundColor(.TextPrimary)

            NavigationLink(destination: NewProjectView()) {
                Text("Use template")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.AccentSoft)
                    .cornerRadius(10)
                    .foregroundColor(.Accent)
            }
        }
        .frame(width: 200)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.Surface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.SurfaceStroke, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct ProcessStepCard: View {
    let step: String
    let title: String
    let systemImage: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.AccentSoft)
                .foregroundColor(.Accent)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.TextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
