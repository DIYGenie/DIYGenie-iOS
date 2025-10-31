//
//  ProjectDetailsView.swift
//  DIYGenieApp
//

import SwiftUI

struct ProjectDetailsView: View {
    let project: Project
    @State private var showingPreview = true
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var plan: PlanResponse?
    @State private var isLoading = false
    @State private var expandedSection: String?
    @Environment(\.dismiss) private var dismiss

    private let gradient = LinearGradient(
        colors: [
            Color(red: 28/255, green: 26/255, blue: 40/255),
            Color(red: 58/255, green: 35/255, blue: 110/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            gradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text(project.name ?? "Project Details")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // MARK: - Hero Image
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: currentImageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 240)
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 240)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(18)
                                    .shadow(radius: 8)
                            case .failure:
                                Color.black.opacity(0.3)
                                    .frame(height: 240)
                                    .frame(maxWidth: .infinity)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.system(size: 30))
                                    )
                                    .cornerRadius(18)
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // Top-right toggle
                        HStack(spacing: 12) {
                            Button(action: { showingPreview = false }) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(10)
                                    .background(showingPreview ? Color.white.opacity(0.15) : Color.white.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            Button(action: { showingPreview = true }) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(10)
                                    .background(showingPreview ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(14)

                        // Bottom-right share
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: shareCurrentImage) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 18, weight: .medium))
                                        .padding(10)
                                        .background(Color.white.opacity(0.25))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(14)
                    }
                    .padding(.horizontal)

                    // MARK: - Summary Cards
                    VStack(alignment: .leading, spacing: 14) {

                        if let goal = project.goal {
                            Text(goal)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 20)
                        }

                        collapsibleCard(title: "Steps", content: plan?.steps ?? ["Loading steps..."])
                        collapsibleCard(title: "Tools & Materials", content: mergedToolsAndMaterials)
                        collapsibleCard(title: "Cost Estimate & Tips", content: costAndTips)
                    }

                    // MARK: - Actions
                    VStack(spacing: 14) {
                        NavigationLink(destination: DetailedBuildPlanView(
                            projectId: project.id ?? "",
                            userId: UserDefaults.standard.string(forKey: "user_id") ?? ""
                        )) {

                            Text("Open Detailed Build Plan")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [
                                        Color(red: 115/255, green: 73/255, blue: 224/255),
                                        Color(red: 146/255, green: 86/255, blue: 255/255)
                                    ], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                        }

                        Button {
                            // Placeholder for marking complete
                        } label: {
                            Text("Mark as Complete")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .task { await loadPlan() }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [image])
                }
            }
        }
    }

    // MARK: - Computed
    private var currentImageURL: URL? {
        if showingPreview {
            if let urlString = project.previewURL, let url = URL(string: urlString) { return url }
        } else {
            if let urlString = project.originalImageUrl, let url = URL(string: urlString) { return url }
        }
        return nil
    }

    private var mergedToolsAndMaterials: [String] {
        let tools = plan?.tools ?? []
        let materials = plan?.materials ?? []
        return tools + materials
    }

    private var costAndTips: [String] {
        var lines: [String] = []
        if let cost = plan?.estimatedCost {
            lines.append("Estimated Cost: $\(Int(cost))")
        }
        if let summary = plan?.summary {
            lines.append(summary)
        }
        return lines
    }

    // MARK: - Load Plan
    private func loadPlan() async {
        guard let id = project.id as String? else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let service = ProjectsService(userId: UserDefaults.standard.string(forKey: "user_id") ?? "")
            plan = try await service.fetchPlan(projectId: id)
        } catch {
            print("Error loading plan: \(error)")
        }
    }

    // MARK: - Share
    private func shareCurrentImage() {
        guard let url = currentImageURL else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    shareImage = image
                    showShareSheet = true
                }
            } catch {
                print("Share failed: \(error)")
            }
        }
    }

    // MARK: - Collapsible Card
    private func collapsibleCard(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    expandedSection = (expandedSection == title) ? nil : title
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: expandedSection == title ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(16)
            }

            if expandedSection == title {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(content, id: \.self) { line in
                        Text("• \(line)")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .background(Color.white.opacity(0.07))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
