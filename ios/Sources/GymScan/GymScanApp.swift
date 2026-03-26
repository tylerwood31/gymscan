import SwiftUI
import SwiftData

@main
struct GymScanApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(GymScanTheme.accent)
        }
        .modelContainer(for: [Gym.self, Equipment.self, Workout.self, UserProfile.self])
    }
}
