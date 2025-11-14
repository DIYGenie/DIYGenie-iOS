//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectDetailsView: View {
    let project: Project

    var body: some View {
        ZStack {
            // Match the NewProjectView gradient-style background so it isn't just black
            LinearGradient(
                gradient: Gradient(colors: [Color("BGStart"), Color("BGEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        if let goal = project.goal, !goal.isEmpty {
                            Text(goal)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        if let budget = project.budget {
                            Text("Budget: \(budget)")
                        }
                        if let skill = project.skillLevel {
                            Text("Skill level: \(skill)")
                        }
                        Text("Project ID: \(project.id)")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)

                    Spacer(minLength: 40)
                }
                .padding(18)
            }
        }
    }
}
