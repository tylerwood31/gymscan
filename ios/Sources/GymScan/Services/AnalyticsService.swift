import Foundation

@Observable
final class AnalyticsService: @unchecked Sendable {
    static let shared = AnalyticsService()

    private init() {}

    func track(_ event: String, properties: [String: Any] = [:]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let propsString = properties.isEmpty ? "{}" : properties.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        print("[Analytics] \(timestamp) | \(event) | {\(propsString)}")
    }
}
