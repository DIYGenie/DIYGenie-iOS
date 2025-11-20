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
                    "notes": "Wear eye and hearing protection.",
                    "steps": [ { "order":1,"title":"Plan & mark studs","details":"Use a stud finder and painter's tape to mark stud centers.","estimatedTime":15 } ],
                    "tools": [ { "name":"Drill/driver","notes":"Already have" } ],
                    "summary":"Modern floating shelves - I want 3 floating shelves in my wall",
                    "materials":[ { "name":"birch plywood 3/4\" (4x8)","quantity":"1 sheet","notes":"" } ],
                    "projectId":"d7ae7eac-5a72-4da1-85f8-0eadaac2521d",
                    "skillLevel":"Intermediate",
                    "costBreakdown":[ { "category":"Materials","amount":122.3,"notes":"" } ],
                    "estimatedCost":152.66,
                    "estimatedDuration":110
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
                    "summary": "Modern floating shelves - I want 3 floating shelves in my wall",
                    "steps": [ { "order":1,"title":"Plan & mark studs","details":"Use a stud finder and painter's tape to mark stud centers.","estimatedTime":15 } ],
                    "materials": [],
                    "tools": []
                },
                "completedSteps": []
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys

        let decoded = try decoder.decode(ProjectAPIResponse.self, from: json)
        let project = decoded.project.toProject()

        XCTAssertEqual(project.id, "d7ae7eac-5a72-4da1-85f8-0eadaac2521d")
        XCTAssertEqual(project.userId, "99198c4b-8470-49e2-895c-75593c5aa181")
        XCTAssertEqual(project.previewStatus, "idle")
        XCTAssertEqual(project.currentStepIndex, 0)
        XCTAssertEqual(project.completedSteps, [])
        XCTAssertEqual(project.planJson?.summary, "Modern floating shelves - I want 3 floating shelves in my wall")
        XCTAssertEqual(project.planJson?.skillLevel, "Intermediate")
        XCTAssertEqual(project.planJson?.costBreakdown?.first?.amount, "122.30")
        XCTAssertEqual(project.planJson?.estimatedCost, "152.66")
        XCTAssertEqual(project.planJson?.estimatedDuration, "110")
        XCTAssertEqual(project.planJson?.steps.first?.title, "Plan & mark studs")
        XCTAssertEqual(project.planJson?.steps.first?.estimatedTime, "15")
    }
}
