import SwiftUI

struct ProjectDetailView: View {
    let project: Project

    @State private var plan: Plan?
    @State private var isRequestingPreview = false
    @State private var isFetchingPlan = false
    @State private var isAttachingPhoto = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Project")
                .toolbar { topBarMenu }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let plan {
            planList(plan)
                .listStyle(.insetGrouped)
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private func planList(_ plan: Plan) -> some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Cost Estimate")
                    Spacer()
                    Text("\(Int(plan.costEstimate.total)) \(plan.costEstimate.currency)")
                        .font(.headline)
                }
                Text("Updated \(plan.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            if !plan.steps.isEmpty {
                Section("Steps") {
                    ForEach(plan.steps) { step in
                        VStack(alignment: .leading, spacing: 4) {
                            if let title = step.title, !title.isEmpty {
                                Text(title).font(.headline)
                            }
                            if let detail = step.detail, !detail.isEmpty {
                                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !plan.tools.isEmpty {
                Section("Tools") { ForEach(plan.tools, id: \.self, content: Text.init) }
            }

            if !plan.materials.isEmpty {
                Section("Materials") {
                    ForEach(plan.materials.indices, id: \.self) { i in
                        let m = plan.materials[i]
                        Text([m.name, qtyUnit(m)].compactMap { $0 }.joined(separator: " • "))
                    }
                }
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Text(project.name).font(.largeTitle).bold()
            Text(project.goal ?? "No goal provided").font(.headline).foregroundStyle(.secondary)
            if let status = project.status { Text(status).font(.subheadline).foregroundStyle(.secondary) }

            if let error { Text(error).foregroundStyle(.red).multilineTextAlignment(.center).padding(.top, 8) }

            VStack(spacing: 10) {
                Button { Task { await attachDemoPhoto() } } label: { label("Attach Demo Photo", system: "photo") }
                    .buttonStyle(.bordered)
                    .disabled(isBusy)

                Button { Task { await requestPreview() } } label: { label("Request Preview", system: "wand.and.stars") }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBusy)

                Button { Task { await fetchPlan() } } label: { label("Load Plan", system: "list.bullet.rectangle") }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBusy)
            }
            .padding(.top, 16)

            if isBusy { ProgressView().padding(.top, 8) }

            Spacer()
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var topBarMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Attach Demo Photo", systemImage: "photo") { Task { await attachDemoPhoto() } }
                Button("Request Preview", systemImage: "wand.and.stars") { Task { await requestPreview() } }
                Button("Load Plan", systemImage: "list.bullet.rectangle") { Task { await fetchPlan() } }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .disabled(isBusy)
        }
    }

    private var isBusy: Bool { isRequestingPreview || isFetchingPlan || isAttachingPhoto }

    private func qtyUnit(_ m: PlanMaterial) -> String? {
        if let q = m.qty, let u = m.unit, !u.isEmpty { return "\(q) \(u)" }
        if let q = m.qty { return "\(q)" }
        return nil
    }

    private func fetchPlan() async {
        guard let uuid = UUID(uuidString: project.id) else { error = "Invalid project id"; return }
        isFetchingPlan = true; defer { isFetchingPlan = false }
        error = nil
        do {
            plan = try await ProjectsService.shared.fetchPlan(projectId: uuid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func attachDemoPhoto() async {
        guard let uuid = UUID(uuidString: project.id) else { error = "Invalid project id"; return }
        isAttachingPhoto = true; defer { isAttachingPhoto = false }
        error = nil
        do {
            // Replace with your real image URL or Supabase upload result
            let ok = try await ProjectsService.shared.attachPhoto(
                projectId: uuid,
                url: URL(string: "https://example.com/photo.jpg")!
            )
            if !ok { self.error = "Photo attach failed" }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func requestPreview() async {
        guard let uuid = UUID(uuidString: project.id) else { error = "Invalid project id"; return }
        isRequestingPreview = true; defer { isRequestingPreview = false }
        error = nil
        do {
            // Assuming this triggers some preview generation on the backend
            _ = try await ProjectsService.shared.requestPreview(projectId: uuid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func label(_ title: String, system: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(title).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProjectDetailView(
        project: Project(id: UUID().uuidString, name: "Demo Project", goal: "Smoke test")
    )
}
