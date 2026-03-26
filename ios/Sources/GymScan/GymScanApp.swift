import SwiftUI
import SwiftData

@main
struct GymScanApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Gym.self, Equipment.self, Workout.self])
    }
}
