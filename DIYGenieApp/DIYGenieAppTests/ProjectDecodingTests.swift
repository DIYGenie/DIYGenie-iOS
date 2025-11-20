import XCTest
@testable import DIYGenieApp

final class ProjectDecodingTests: XCTestCase {
    func testProjectAPIResponseDecodesPlanAndCompletionState() throws {
        let json = """
        {
            "ok": true,
            "project": {
                "id": "d7ae7eac-5a72-4da1-85f8-0eadaac2521d",
                "user_id": "99198c4b-8470-49e2-895c-75593c5aa181",
                "name": "Shelves – DIY Genie",
                "goal": "I want 3 floating shelves in my wall",
                "budget": "$$",
                "budget_tier": null,
                "skill_level": null,
                "status": "draft",
                "created_at": "2025-11-20T05:44:16.651667+00:00",
                "updated_at": "2025-11-20T05:44:19.400945+00:00",
                "preview_url": null,
                "input_image_url": "https://example.com/image.jpg",
                "plan_json": {
                    "summary": "Floating shelves plan",
                    "estimated_cost": "$120",
                    "estimated_duration": "1 day",
                    "steps": [
                        {"order": 1, "title": "Measure and mark", "details": "Use a level"}
                    ],
                    "materials": [
                        {"name": "Shelf board", "quantity": "3"}
                    ],
                    "tools": [
                        {"name": "Drill"}
                    ],
                    "notes": "Use wall anchors"
                },
                "completed_steps": [],
                "current_step_index": 0,
                "preview_status": "idle",
                "preview_meta": {
                    "roi": {"h": 0.16, "w": 0.16, "x": 0.6, "y": 0.26}
                },
                "is_demo": false,
                "photo_url": null,
                "planJson": {
                    "summary": "Floating shelves plan",
                    "steps": [],
                    "materials": [],
                    "tools": []
                },
                "completedSteps": []
            }
        }
        """.data(using: .utf8)!

        struct Envelope: Decodable {
            let ok: Bool
            let project: Project
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(Envelope.self, from: json)

        XCTAssertEqual(decoded.project.id, "d7ae7eac-5a72-4da1-85f8-0eadaac2521d")
        XCTAssertEqual(decoded.project.userId, "99198c4b-8470-49e2-895c-75593c5aa181")
        XCTAssertEqual(decoded.project.previewStatus, "idle")
        XCTAssertEqual(decoded.project.currentStepIndex, 0)
        XCTAssertEqual(decoded.project.completedSteps, [])
        XCTAssertEqual(decoded.project.planJson?.summary, "Floating shelves plan")
        XCTAssertEqual(decoded.project.planJson?.steps.first?.title, "Measure and mark")
    }
}
