import SwiftUI
import SwiftData

// MARK: - Onboarding Data (transient state during onboarding flow)

@Observable
final class OnboardingData {
    var fitnessLevel: String = ""
    var preferredActivities: Set<String> = []
    var movementsToAvoid: Set<String> = []
    var customAvoidanceNote: String = ""
    var travelGoal: String = ""
    var gender: String? = nil
    var startTime: Date = Date()
    var lastScreenChangeTime: Date = Date()
}

// MARK: - Onboarding Container

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage: Int = 0
    @State private var data = OnboardingData()
    @State private var isAdvancing = false

    var onComplete: ((FirstScanChoice) -> Void)?

    private let totalPages = 7
    private let analytics = AnalyticsService.shared

    var body: some View {
        ZStack {
            GymScanTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome screen)
                if currentPage > 0 {
                    progressDots
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }

                // Screen content
                TabView(selection: $currentPage) {
                    WelcomeScreen(onContinue: advanceToNext)
                        .tag(0)

                    FitnessLevelScreen(data: data, onSelected: advanceToNext)
                        .tag(1)

                    ActivityPreferencesScreen(data: data, onContinue: advanceToNext)
                        .tag(2)

                    AvoidancesScreen(data: data, onContinue: advanceToNext)
                        .tag(3)

                    GoalScreen(data: data, onSelected: advanceToNext)
                        .tag(4)

                    GenderScreen(data: data, onSelected: advanceToNext)
                        .tag(5)

                    FirstScanPromptScreen(onChoice: handleFirstScanChoice)
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .disabled(isAdvancing)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            data.startTime = Date()
            data.lastScreenChangeTime = Date()
            analytics.track("onboarding_started")
            analytics.track("onboarding_screen_viewed", properties: [
                "screen_name": "welcome",
                "screen_index": 0
            ])
        }
        .onChange(of: currentPage) { _, newValue in
            data.lastScreenChangeTime = Date()
            let screenNames = ["welcome", "fitness_level", "activity_preferences", "avoidances", "goal", "gender", "first_scan_prompt"]
            analytics.track("onboarding_screen_viewed", properties: [
                "screen_name": screenNames[newValue],
                "screen_index": newValue
            ])
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? GymScanTheme.accent : GymScanTheme.textSecondary.opacity(0.3))
                    .frame(width: index == currentPage ? 10 : 7, height: index == currentPage ? 10 : 7)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    // MARK: - Navigation

    private func advanceToNext() {
        guard !isAdvancing, currentPage < totalPages - 1 else { return }
        isAdvancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
            isAdvancing = false
        }
    }

    // MARK: - Completion

    private func handleFirstScanChoice(_ choice: FirstScanChoice) {
        let totalTime = Date().timeIntervalSince(data.startTime)
        analytics.track("onboarding_completed", properties: [
            "total_time_seconds": Int(totalTime)
        ])
        analytics.track("first_scan_choice", properties: [
            "choice": choice.rawValue
        ])

        // Save user profile to SwiftData
        let profile = UserProfile(
            fitnessLevel: data.fitnessLevel,
            preferredActivities: Array(data.preferredActivities),
            movementsToAvoid: Array(data.movementsToAvoid),
            customAvoidanceNote: data.customAvoidanceNote.isEmpty ? nil : data.customAvoidanceNote,
            travelGoal: data.travelGoal,
            gender: data.gender,
            onboardingCompletedAt: Date()
        )
        modelContext.insert(profile)

        onComplete?(choice)
    }
}

// MARK: - First Scan Choice

enum FirstScanChoice: String {
    case scanNow = "scan_now"
    case demo = "demo"
}
