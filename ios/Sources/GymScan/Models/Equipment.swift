import Foundation
import SwiftData

@Model
final class Equipment {
    var id: UUID
    var typeRaw: String
    var details: String?
    var confidenceRaw: String
    var userConfirmed: Bool
    var isEnabled: Bool

    var type: EquipmentType {
        get { EquipmentType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var confidence: ConfidenceLevel {
        get { ConfidenceLevel(rawValue: confidenceRaw) ?? .medium }
        set { confidenceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        type: EquipmentType,
        details: String? = nil,
        confidence: ConfidenceLevel = .medium,
        userConfirmed: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.details = details
        self.confidenceRaw = confidence.rawValue
        self.userConfirmed = userConfirmed
        self.isEnabled = isEnabled
    }
}
