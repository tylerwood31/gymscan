import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var fitnessLevel: String    // beginner, intermediate, consistent, advanced
    var preferredActivities: [String]  // strength, cardio, hiit, yoga, anything
    var movementsToAvoid: [String]     // heavy_barbell, jumping, overhead, running
    var customAvoidanceNote: String?
    var travelGoal: String      // feel_good, maintain, push
    var gender: String?         // male, female, nil if skipped
    var onboardingCompletedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fitnessLevel: String = "intermediate",
        preferredActivities: [String] = [],
        movementsToAvoid: [String] = [],
        customAvoidanceNote: String? = nil,
        travelGoal: String = "feel_good",
        gender: String? = nil,
        onboardingCompletedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fitnessLevel = fitnessLevel
        self.preferredActivities = preferredActivities
        self.movementsToAvoid = movementsToAvoid
        self.customAvoidanceNote = customAvoidanceNote
        self.travelGoal = travelGoal
        self.gender = gender
        self.onboardingCompletedAt = onboardingCompletedAt
        self.createdAt = createdAt
    }
}
