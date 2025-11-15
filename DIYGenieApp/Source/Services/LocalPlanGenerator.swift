//
//  LocalPlanGenerator.swift
//  DIYGenieApp
//
//  Generates a deterministic DIY plan when the network backend
//  is unavailable. This keeps the end-to-end project flow usable
//  during development and demos.
//

import Foundation

struct LocalPlanGenerator {
    func makePlan(for project: Project) -> PlanResponse {
        let subject = normalizedSubject(from: project)
        let skill = (project.skillLevel ?? "Intermediate").lowercased()
        let budgetSymbol = project.budget ?? "$$"

        let summary = "This guided plan walks you through how to \(subject) with materials and effort tuned for your \(skillDescription(skill)) skill level."

        let steps = makeSteps(subject: subject, skill: skill)
        let materials = makeMaterials(subject: subject)
        let tools = makeTools(skill: skill)
        let estimate = estimatedCost(for: budgetSymbol)

        return PlanResponse(
            summary: summary,
            steps: steps,
            materials: materials,
            tools: tools,
            estimatedCost: estimate
        )
    }
}

// MARK: - Private helpers
private extension LocalPlanGenerator {
    func normalizedSubject(from project: Project) -> String {
        let trimmedGoal = (project.goal ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGoal.isEmpty {
            return trimmedGoal
        }
        return project.name
    }

    func skillDescription(_ skill: String) -> String {
        switch skill {
        case "beginner":
            return "beginner"
        case "advanced":
            return "advanced"
        default:
            return "intermediate"
        }
    }

    func makeSteps(subject: String, skill: String) -> [String] {
        var base: [String] = [
            "Review the inspiration photo and confirm the measured area reflects the part of the room where you'll work.",
            "Sketch a quick layout for \(subject) including approximate dimensions and how it fits with existing furniture.",
            "Gather the listed materials and dry-fit everything in the space to make sure the plan feels right.",
            "Complete the build or installation, double-checking level, alignment, and secure fasteners as you go.",
            "Style the finished project and take an after photo to compare against your original goal."
        ]

        if skill == "beginner" {
            base.insert("Practice any new tool motions (like drilling or using a stud finder) on scrap material before touching the real space.", at: 2)
            base.append("Invite a friend or family member to help with lifting and final inspection for confidence.")
        } else if skill == "advanced" {
            base.insert("Plan for pro touches such as concealed fasteners or integrated lighting to elevate the final result.", at: 3)
            base.append("Finish by sealing or finishing surfaces so they hold up to daily use.")
        }

        return base
    }

    func makeMaterials(subject: String) -> [String] {
        [
            "Primary components for \(subject) (lumber, panels, or specialty pieces).",
            "Fasteners suited to your wall type (anchors, screws, or construction adhesive).",
            "Finishing supplies like paint, stain, or caulk to blend with the room.",
            "Protective gear: drop cloths, painter's tape, and safety glasses."
        ]
    }

    func makeTools(skill: String) -> [String] {
        var tools = [
            "Measuring tape and pencil",
            "Level or laser level",
            "Power drill/driver with appropriate bits"
        ]

        if skill == "beginner" {
            tools.append(contentsOf: [
                "Stud finder or multi-surface detector",
                "Sanding block for smoothing edges"
            ])
        } else {
            tools.append(contentsOf: [
                "Miter saw or circular saw",
                "Finish nailer or brad nailer"
            ])
        }

        tools.append("Safety gear: eye, ear, and dust protection")
        return tools
    }

    func estimatedCost(for budget: String) -> Double {
        switch budget {
        case "$": return 75
        case "$$$": return 850
        default: return 275
        }
    }
}

