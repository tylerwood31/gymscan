import SwiftUI

struct AvoidancesScreen: View {
    @Bindable var data: OnboardingData
    var onContinue: () -> Void

    @State private var pillsVisible = false
    @FocusState private var otherFieldFocused: Bool

    private let analytics = AnalyticsService.shared

    private let avoidances: [(id: String, label: String)] = [
        ("heavy_barbell", "Heavy barbell lifts"),
        ("jumping", "Jumping / impact"),
        ("overhead", "Overhead pressing"),
        ("running", "Running"),
        ("none", "None \u{2014} I'm game for anything"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text("Anything you'd\nrather skip?")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            VStack(spacing: 10) {
                FlowLayout(spacing: 10) {
                    ForEach(Array(avoidances.enumerated()), id: \.element.id) { index, avoidance in
                        let isSelected = data.movementsToAvoid.contains(avoidance.id)
                        AvoidancePill(label: avoidance.label, isSelected: isSelected)
                            .opacity(pillsVisible ? 1 : 0)
                            .offset(y: pillsVisible ? 0 : 15)
                            .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.06), value: pillsVisible)
                            .onTapGesture {
                                handleSelection(avoidance.id)
                            }
                    }
                }

                // Other text field
                HStack(spacing: 12) {
                    Text("Other:")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(GymScanTheme.textSecondary)

                    TextField("", text: $data.customAvoidanceNote, prompt: Text("e.g., lower back issues").foregroundStyle(GymScanTheme.textSecondary.opacity(0.5)))
                        .font(.system(size: 15))
                        .foregroundStyle(GymScanTheme.textPrimary)
                        .focused($otherFieldFocused)
                        .tint(GymScanTheme.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GymScanTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(otherFieldFocused ? GymScanTheme.accent.opacity(0.5) : GymScanTheme.surfaceLight, lineWidth: 1)
                )
                .opacity(pillsVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.3), value: pillsVisible)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button(action: {
                otherFieldFocused = false
                onContinue()
            }) {
                Text("CONTINUE")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(GymScanTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(GymScanTheme.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation {
                pillsVisible = true
            }
        }
        .onTapGesture {
            otherFieldFocused = false
        }
    }

    private func handleSelection(_ id: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if id == "none" {
                // Selecting "None" clears everything else
                data.movementsToAvoid = ["none"]
            } else {
                // Selecting a real avoidance removes "none"
                data.movementsToAvoid.remove("none")
                if data.movementsToAvoid.contains(id) {
                    data.movementsToAvoid.remove(id)
                } else {
                    data.movementsToAvoid.insert(id)
                }
            }
        }
        analytics.track("onboarding_option_selected", properties: [
            "screen_name": "avoidances",
            "value": id
        ])
    }
}

// MARK: - Avoidance Pill

private struct AvoidancePill: View {
    let label: String
    let isSelected: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(isSelected ? GymScanTheme.accent : GymScanTheme.textPrimary.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? GymScanTheme.accent.opacity(0.12) : GymScanTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? GymScanTheme.accent : GymScanTheme.surfaceLight, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
    }
}
