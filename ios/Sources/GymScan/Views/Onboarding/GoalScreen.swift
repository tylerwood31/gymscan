import SwiftUI

struct GoalScreen: View {
    var data: OnboardingData
    var onSelected: () -> Void

    @State private var selectedGoal: String? = nil
    @State private var cardsVisible = false

    private let analytics = AnalyticsService.shared

    private let goals: [(id: String, label: String, icon: String)] = [
        ("feel_good", "Stay active and feel good", "heart.fill"),
        ("maintain", "Maintain my routine", "arrow.triangle.2.circlepath"),
        ("push", "Push myself wherever I am", "flame.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text("When you're on the\nroad, what's your goal?")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            VStack(spacing: 12) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    GoalCard(
                        label: goal.label,
                        icon: goal.icon,
                        isSelected: selectedGoal == goal.id
                    )
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: cardsVisible)
                    .onTapGesture {
                        guard selectedGoal == nil else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGoal = goal.id
                        }
                        data.travelGoal = goal.id
                        analytics.track("onboarding_option_selected", properties: [
                            "screen_name": "goal",
                            "value": goal.id
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

// MARK: - Goal Card

private struct GoalCard: View {
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
