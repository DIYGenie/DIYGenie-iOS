//
//  Project.swift
//  DIYGenieApp
//

import Foundation

struct Project: Identifiable, Codable {
    var id: String
    var userId: String?
    var name: String?
    var goal: String?
    var skillLevel: String?
    var budget: String?
    var createdAt: String?
    
    // Image fields
    var inputImageURL: String?
    var previewURL: String?
    var outputImageURL: String?
}
