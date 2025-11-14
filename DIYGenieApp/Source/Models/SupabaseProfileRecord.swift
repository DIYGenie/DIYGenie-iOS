//
//  SupabaseProfileRecord.swift
//  DIYGenieApp
//

import Foundation

struct SupabaseProfileRecord: Codable {
    let userId: String
    let subscriptionTier: String?
    let planTier: String?
    let planQuotaMonthly: Int?
    let planCreditsUsedMonth: Int?
    let creditsMonthKey: String?
    let isSubscribed: Bool?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case subscriptionTier = "subscription_tier"
        case planTier = "plan_tier"
        case planQuotaMonthly = "plan_quota_monthly"
        case planCreditsUsedMonth = "plan_credits_used_month"
        case creditsMonthKey = "credits_month_key"
        case isSubscribed = "is_subscribed"
    }
}
