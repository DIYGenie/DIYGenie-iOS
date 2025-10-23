import SwiftUI

struct NewProjectView: View {
    @State private var title: String = ""
    @State private var goal: String = ""
    @State private var budget: String = "$"
    @State private var skillLevel: String = "Beginner"
    
    // States to present sheets
    @State private var showScanView: Bool = false
    @State private var showMeasureView: Bool = false
    @State private var showPhotoPicker: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Project name
                TextField("Project name", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)

                // Goal description
                TextEditor(text: $goal)
                    .frame(height: 120)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(
                        Text(goal.isEmpty ? "Describe your goal..." : "")
                            .foregroundColor(.secondary)
                            .padding(.leading, 8),
                        alignment: .topLeading
                    )

                // Budget picker
                Menu {
                    Button("$") { budget = "$" }
                    Button("$$") { budget = "$$" }
                    Button("$$$") { budget = "$$$" }
                } label: {
                    HStack {
                        Text("Budget")
                        Spacer()
                        Text(budget)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                }

                // Skill level picker
                Menu {
                    Button("Beginner") { skillLevel = "Beginner" }
                    Button("Intermediate") { skillLevel = "Intermediate" }
                    Button("Advanced") { skillLevel = "Advanced" }
                } label: {
                    HStack {
                        Text("Skill level")
                        Spacer()
                        Text(skillLevel)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                }

                // Action buttons grouped separately
                VStack(spacing: 16) {
                    // First row: scan and measure
                    HStack(spacing: 16) {
                        // Scan room button
                        Button(action: {
                            showScanView = true
                        }) {
                            VStack {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 28, weight: .semibold))
                                Text("Scan room")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }

                        // Measure area button
                        Button(action: {
                            showMeasureView = true
                        }) {
                            VStack {
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .font(.system(size: 28, weight: .semibold))
                                Text("Measure area")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }

                    // Second row: upload photo (full width)
                    Button(action: {
                        showPhotoPicker = true
                    }) {
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 28, weight: .semibold))
                            Text("Upload photo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(Color.white)
                        .foregroundColor(.purple)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                    }
                }
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [.purple, .white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        // Present scanning, measuring, and photo picker views
        .sheet(isPresented: $showScanView) {
            ARScanView().ignoresSafeArea()
        }
        .sheet(isPresented: $showMeasureView) {
            MeasureOverlayView { inches in
                // handle measurement result here
                showMeasureView = false
            }.ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoPicker) {
            // Placeholder photo picker view
            Text("Photo picker coming soon")
                .font(.headline)
                .padding()
        }
    }
}
