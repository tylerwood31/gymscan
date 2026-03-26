import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var gymId: UUID
    var targetMusclesRaw: [String]
    var durationMinutes: Int
    var exercisesData: Data?
    var createdAt: Date
    var completed: Bool
    var completedAt: Date?

    var targetMuscles: [MuscleGroup] {
        get { targetMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { targetMusclesRaw = newValue.map(\.rawValue) }
    }

    var exercises: [Exercise] {
        get {
            guard let data = exercisesData else { return [] }
            return (try? JSONDecoder().decode([Exercise].self, from: data)) ?? []
        }
        set {
            exercisesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        gymId: UUID,
        targetMuscles: [MuscleGroup] = [],
        durationMinutes: Int = 30,
        exercises: [Exercise] = [],
        createdAt: Date = Date(),
        completed: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.gymId = gymId
        self.targetMusclesRaw = targetMuscles.map(\.rawValue)
        self.durationMinutes = durationMinutes
        self.exercisesData = try? JSONEncoder().encode(exercises)
        self.createdAt = createdAt
        self.completed = completed
        self.completedAt = completedAt
    }
}

struct Exercise: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var equipmentTypeRaw: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var notes: String?
    var primaryMusclesRaw: [String]
    var order: Int

    var equipmentType: EquipmentType {
        get { EquipmentType(rawValue: equipmentTypeRaw) ?? .other }
        set { equipmentTypeRaw = newValue.rawValue }
    }

    var primaryMuscles: [MuscleGroup] {
        primaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
    }

    /// Estimated time for this exercise in seconds (work + rest for all sets)
    var estimatedSeconds: Int {
        sets * (45 + restSeconds)
    }

    init(
        id: UUID = UUID(),
        name: String,
        equipmentType: EquipmentType,
        sets: Int,
        reps: String,
        restSeconds: Int,
        notes: String? = nil,
        primaryMuscles: [String] = [],
        order: Int
    ) {
        self.id = id
        self.name = name
        self.equipmentTypeRaw = equipmentType.rawValue
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
        self.primaryMusclesRaw = primaryMuscles
        self.order = order
    }

    enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, notes, order
        case equipmentTypeRaw = "equipment_type"
        case restSeconds = "rest_seconds"
        case primaryMusclesRaw = "primary_muscles"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        equipmentTypeRaw = try container.decode(String.self, forKey: .equipmentTypeRaw)
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(String.self, forKey: .reps)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        primaryMusclesRaw = (try? container.decode([String].self, forKey: .primaryMusclesRaw)) ?? []
        order = try container.decode(Int.self, forKey: .order)
    }
}
