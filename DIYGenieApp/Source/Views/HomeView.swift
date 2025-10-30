//
//  HomeView.swift
//  DIYGenieApp
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var recentProjects: [Project] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back, Tye")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Ready to start your next DIY project?")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)

                // MARK: - Hero Section
                VStack(spacing: 14) {
                    Text("Bring your ideas to life")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text("Describe your project or start with a template → Take a photo of your space → Get your custom step-by-step plan.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button(action: {
                        // Navigate to NewProjectView
                        // Example: RootTabsView().selectedTab = .new
                    }) {
                        Text("Start New Project")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color.purple, Color(hue: 0.78, saturation: 0.9, brightness: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(colors: [Color.black.opacity(0.4), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .padding(.horizontal)

                // MARK: - Template Carousel
                VStack(alignment: .leading, spacing: 16) {
                    Text("Not sure where to begin? Start with a template.")
                        .font(.headline)
                        .foregroundColor(Color.purple)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(templateProjects) { template in
                                TemplateCard(template: template)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)

                // MARK: - Recent Projects
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Recent Projects")
                        .font(.headline)
                        .foregroundColor(Color.purple)

                    if recentProjects.isEmpty {
                        VStack(spacing: 10) {
                            Text("No projects yet — your next idea starts here!")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(recentProjects) { project in
                                ProjectCard(project: project)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 80)
            }
            .padding(.top, 32)
        }
        .background(LinearGradient(colors: [Color(red: 0.05, green: 0.03, blue: 0.1), Color(red: 0.1, green: 0.08, blue: 0.18)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .onAppear {
            loadRecentProjects()
        }
    }

    // MARK: - Load Recent Projects
    func loadRecentProjects() {
        // TODO: Integrate Supabase fetch later
        // currently showing demo data placeholder
        self.recentProjects = []
    }
}

// MARK: - Template Model & Card
struct TemplateProject: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

let templateProjects: [TemplateProject] = [
    TemplateProject(title: "Floating Shelves", subtitle: "Clean, modern storage that fits any space.", imageName: "shelves"),
    TemplateProject(title: "Entryway Bench with Hooks", subtitle: "Simple storage meets design.", imageName: "bench"),
    TemplateProject(title: "Laundry Room Refresh", subtitle: "Brighten and organize your utility space.", imageName: "laundry")
]

struct TemplateCard: View {
    let template: TemplateProject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Image(template.imageName)
                        .resizable()
                        .scaledToFill()
                )
                .frame(width: 240, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(template.title)
                .font(.headline)
                .foregroundColor(.white)

            Text(template.subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)

            Button(action: {
                // Navigate to NewProjectView with pre-filled name/desc
            }) {
                Text("Create")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [Color.purple, Color(hue: 0.78, saturation: 0.9, brightness: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
        }
        .frame(width: 240)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}
