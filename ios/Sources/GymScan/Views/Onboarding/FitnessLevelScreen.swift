import SwiftUI

struct FitnessLevelScreen: View {
    var data: OnboardingData
    var onSelected: () -> Void

    @State private var selectedLevel: String? = nil
    @State private var cardsVisible = false

    private let analytics = AnalyticsService.shared

    private let levels: [(id: String, label: String, icon: String)] = [
        ("beginner", "Just getting started", "figure.walk"),
        ("intermediate", "I work out sometimes", "figure.strengthtraining.traditional"),
        ("consistent", "Pretty consistent", "figure.run"),
        ("advanced", "Years of experience", "figure.strengthtraining.functional"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text("How would you\ndescribe yourself?")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            VStack(spacing: 12) {
                ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                    FitnessLevelCard(
                        label: level.label,
                        icon: level.icon,
                        isSelected: selectedLevel == level.id
                    )
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: cardsVisible)
                    .onTapGesture {
                        guard selectedLevel == nil else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLevel = level.id
                        }
                        data.fitnessLevel = level.id
                        analytics.track("onboarding_option_selected", properties: [
                            "screen_name": "fitness_level",
                            "value": level.id
                        ])
                        onSelected()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            withAnimation {
                cardsVisible = true
            }
        }
    }
}

// MARK: - Fitness Level Card

private struct FitnessLevelCard: View {
    let label: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isSelected ? GymScanTheme.accent : GymScanTheme.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? GymScanTheme.accent.opacity(0.15) : GymScanTheme.surfaceLight.opacity(0.5))
                )

            Text(label)
                .font(.system(size: 17, weight: .medium, design: .default))
                .foregroundStyle(isSelected ? GymScanTheme.textPrimary : GymScanTheme.textPrimary.opacity(0.9))

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(GymScanTheme.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? GymScanTheme.accent.opacity(0.08) : GymScanTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? GymScanTheme.accent : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
    }
}
