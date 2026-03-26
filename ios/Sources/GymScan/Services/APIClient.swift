import Foundation

@Observable
final class APIClient: Sendable {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: String = "https://gymscan-api.onrender.com") {
        self.baseURL = URL(string: baseURL)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Scan

    func scanEquipment(frames: [Data]) async throws -> ScanResponse {
        let base64Frames = frames.map { $0.base64EncodedString() }
        let body = ScanRequest(frames: base64Frames)
        return try await post("/api/scan", body: body)
    }

    func confirmEquipment(gymId: String, equipment: [EquipmentConfirmationDTO]) async throws -> ConfirmResponse {
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
        let _: WorkoutCompleteResponse = try await post("/api/workout/\(workoutId)/complete", body: body)
    }

    // MARK: - Gym

    func getGym(gymId: String) async throws -> GymDetailResponse {
        return try await get("/api/gym/\(gymId)")
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            var detail: String?
            if let data, let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                detail = body["detail"] as? String
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, detail: detail)
        }
    }
}

// MARK: - Request Types

struct ScanRequest: Encodable {
    let frames: [String]
}

struct ConfirmRequest: Encodable {
    let equipment: [EquipmentConfirmationDTO]
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

struct WorkoutCompleteRequest: Encodable {
    let completedAt: String
    let exercisesCompleted: [Int]

    enum CodingKeys: String, CodingKey {
        case completedAt = "completed_at"
        case exercisesCompleted = "exercises_completed"
    }
}

// MARK: - DTO for sending equipment confirmation to backend

struct EquipmentConfirmationDTO: Codable {
    let type: String
    let details: String
    let userConfirmed: Bool

    enum CodingKeys: String, CodingKey {
        case type, details
        case userConfirmed = "user_confirmed"
    }
}

// MARK: - Response Types

struct ScanResponse: Decodable {
    let gymId: String
    let equipment: [DetectedEquipmentResponse]

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case equipment
    }
}

struct DetectedEquipmentResponse: Decodable {
    let type: String
    let details: String
    let confidence: String
}

struct ConfirmResponse: Decodable {
    let gymId: String
    let equipmentFinal: [EquipmentConfirmationDTO]

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case equipmentFinal = "equipment_final"
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
    let notes: String
    let primaryMuscles: [String]
    let order: Int

    enum CodingKeys: String, CodingKey {
        case name, sets, reps, notes, order
        case equipmentType = "equipment_type"
        case restSeconds = "rest_seconds"
        case primaryMuscles = "primary_muscles"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        equipmentType = try container.decode(String.self, forKey: .equipmentType)
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(String.self, forKey: .reps)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
        notes = (try? container.decode(String.self, forKey: .notes)) ?? ""
        primaryMuscles = (try? container.decode([String].self, forKey: .primaryMuscles)) ?? []
        order = try container.decode(Int.self, forKey: .order)
    }
}

struct WorkoutCompleteResponse: Decodable {
    let saved: Bool
}

struct GymDetailResponse: Decodable {
    let gymId: String
    let name: String?
    let equipment: [EquipmentConfirmationDTO]
    let createdAt: String
    let workouts: [String]

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case name, equipment, workouts
        case createdAt = "created_at"
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, detail: String?)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let detail):
            if let detail {
                return "Server error (\(statusCode)): \(detail)"
            }
            return "Server error (status \(statusCode))"
        case .decodingError:
            return "Could not parse server response"
        }
    }
}
