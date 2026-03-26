import Foundation
import SwiftData

@Model
final class Gym {
    var id: UUID
    var name: String?
    @Relationship(deleteRule: .cascade) var equipment: [Equipment]
    var createdAt: Date

    init(id: UUID = UUID(), name: String? = nil, equipment: [Equipment] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.equipment = equipment
        self.createdAt = createdAt
    }
}
