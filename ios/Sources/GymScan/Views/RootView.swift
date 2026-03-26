import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var hasCompletedOnboarding = false
    @State private var firstScanChoice: FirstScanChoice? = nil

    var body: some View {
        Group {
            if profiles.isEmpty && !hasCompletedOnboarding {
                OnboardingContainerView { choice in
                    firstScanChoice = choice
                    hasCompletedOnboarding = true
                }
                .transition(.opacity)
            } else {
                MainTabView(initialScanChoice: firstScanChoice)
                    .transition(.opacity)
                    .onAppear {
                        // Clear the choice after it's been consumed
                        firstScanChoice = nil
                    }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: profiles.isEmpty)
    }
}
