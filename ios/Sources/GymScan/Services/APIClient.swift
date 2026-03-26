import Foundation

@Observable
final class APIClient: Sendable {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = URL(string: baseURL)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    // MARK: - Scan

    func scanEquipment(frames: [Data]) async throws -> ScanResponse {
        let base64Frames = frames.map { $0.base64EncodedString() }
        let body = ScanRequest(frames: base64Frames)
        return try await post("/api/scan", body: body)
    }

    func confirmEquipment(gymId: String, equipment: [EquipmentConfirmation]) async throws -> ConfirmResponse {
        let body = ConfirmRequest(equipment: equipment)
        return try await post("/api/scan/\(gymId)/confirm", body: body)
    }

    // MARK: - Workout

    func generateWorkout(gymId: String, targetMuscles: [String], durationMinutes: Int) async throws -> WorkoutResponse {
        let body = WorkoutGenerateRequest(
            gymId: gymId,
            targetMuscles: targetMuscles,
            durationMinutes: durationMinutes
        )
        return try await post("/api/workout/generate", body: body)
    }

    func completeWorkout(workoutId: String, completedAt: Date, exercisesCompleted: [Int]) async throws {
        let body = WorkoutCompleteRequest(
            completedAt: ISO8601DateFormatter().string(from: completedAt),
            exercisesCompleted: exercisesCompleted
        )
        let _: EmptyResponse = try await post("/api/workout/\(workoutId)/complete", body: body)
    }

    // MARK: - Gym

    func getGym(gymId: String) async throws -> GymResponse {
        return try await get("/api/gym/\(gymId)")
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Request/Response Types

struct ScanRequest: Encodable {
    let frames: [String]
}

struct ScanResponse: Decodable {
    let gymId: String
    let equipment: [EquipmentResponse]

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case equipment
    }
}

struct EquipmentResponse: Decodable {
    let type: String
    let details: String?
    let confidence: String
}

struct EquipmentConfirmation: Encodable {
    let type: String
    let details: String?
    let userConfirmed: Bool

    enum CodingKeys: String, CodingKey {
        case type, details
        case userConfirmed = "user_confirmed"
    }
}

struct ConfirmRequest: Encodable {
    let equipment: [EquipmentConfirmation]
}

struct ConfirmResponse: Decodable {
    let gymId: String
    let equipmentFinal: [EquipmentResponse]

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case equipmentFinal = "equipment_final"
    }
}

struct WorkoutGenerateRequest: Encodable {
    let gymId: String
    let targetMuscles: [String]
    let durationMinutes: Int

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case targetMuscles = "target_muscles"
        case durationMinutes = "duration_minutes"
    }
}

struct WorkoutResponse: Decodable {
    let workoutId: String
    let exercises: [ExerciseResponse]

    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case exercises
    }
}

struct ExerciseResponse: Decodable {
    let name: String
    let equipmentType: String
    let sets: Int
    let reps: String
    let restSeconds: Int
    let notes: String?
    let order: Int

    enum CodingKeys: String, CodingKey {
        case name, sets, reps, notes, order
        case equipmentType = "equipment_type"
        case restSeconds = "rest_seconds"
    }
}

struct WorkoutCompleteRequest: Encodable {
    let completedAt: String
    let exercisesCompleted: [Int]

    enum CodingKeys: String, CodingKey {
        case completedAt = "completed_at"
        case exercisesCompleted = "exercises_completed"
    }
}

struct GymResponse: Decodable {
    let gymId: String
    let name: String?
    let equipment: [EquipmentResponse]

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case name, equipment
    }
}

struct EmptyResponse: Decodable {}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error (status \(statusCode))"
        case .decodingError:
            return "Could not parse server response"
        }
    }
}
