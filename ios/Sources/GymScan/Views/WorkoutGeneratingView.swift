import SwiftUI

struct WorkoutGeneratingView: View {
    @Bindable var workoutViewModel: WorkoutViewModel
    @Bindable var scanViewModel: ScanViewModel
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext

    @State private var currentPhrase = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var dotsCount = 0
    @State private var showError = false

    private let phrases = [
        "Analyzing your equipment",
        "Matching exercises to your profile",
        "Balancing muscle groups",
        "Calculating sets and rest times",
        "Building your workout"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(GymScanTheme.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(GymScanTheme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(GymScanTheme.accent)
                    .rotationEffect(.degrees(iconRotation))
            }
            .padding(.bottom, 40)

            // Cycling status text
            Text(phrases[currentPhrase] + String(repeating: ".", count: dotsCount))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(GymScanTheme.textPrimary)
                .animation(.easeInOut(duration: 0.3), value: currentPhrase)
                .padding(.bottom, 8)

            // Subtitle
            Text("Personalizing for your fitness level and goals")
                .font(.system(size: 14))
                .foregroundStyle(GymScanTheme.textSecondary)

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GymScanTheme.surface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(GymScanTheme.accentGradient)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: currentPhrase)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .background(GymScanTheme.background)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK") { path.removeLast() }
        } message: {
            Text(workoutViewModel.error ?? "Something went wrong")
        }
        .task {
            await generateWithAnimation()
        }
    }

    private var progress: CGFloat {
        CGFloat(currentPhrase + 1) / CGFloat(phrases.count)
    }

    private func generateWithAnimation() async {
        // Start animations
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }

        // Cycle dots
        let dotsTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            Task { @MainActor in
                dotsCount = (dotsCount + 1) % 4
            }
        }

        // Cycle phrases
        let phraseTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            Task { @MainActor in
                if currentPhrase < phrases.count - 1 {
                    currentPhrase += 1
                }
            }
        }

        // Subtle icon animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            iconRotation = 5
        }

        // Actually generate the workout
        guard let gymId = scanViewModel.currentGymId else {
            showError = true
            return
        }

        await workoutViewModel.generateWorkout(gymId: gymId, modelContext: modelContext)

        // Stop timers
        dotsTimer.invalidate()
        phraseTimer.invalidate()

        // Ensure minimum 2 seconds of animation so it doesn't feel instant
        try? await Task.sleep(for: .seconds(0.5))

        // Show last phrase
        await MainActor.run {
            currentPhrase = phrases.count - 1
        }
        try? await Task.sleep(for: .seconds(0.5))

        // Navigate
        await MainActor.run {
            if workoutViewModel.error != nil {
                showError = true
            } else {
                path.append(ScanFlowStep.workout)
            }
        }
    }
}
