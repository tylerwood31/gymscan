import SwiftUI

struct GenderScreen: View {
    var data: OnboardingData
    var onSelected: () -> Void

    @State private var selected: String? = nil
    @State private var contentVisible = false

    private let analytics = AnalyticsService.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text("One more thing")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .padding(.bottom, 8)

            Text("This helps us personalize exercises.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(GymScanTheme.textSecondary)
                .padding(.bottom, 48)
                .opacity(contentVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: contentVisible)

            HStack(spacing: 14) {
                GenderOption(
                    label: "Male",
                    icon: "figure.stand",
                    isSelected: selected == "male",
                    style: .primary
                )
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: contentVisible)
                .onTapGesture {
                    selectGender("male")
                }

                GenderOption(
                    label: "Female",
                    icon: "figure.stand.dress",
                    isSelected: selected == "female",
                    style: .primary
                )
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.22), value: contentVisible)
                .onTapGesture {
                    selectGender("female")
                }

                GenderOption(
                    label: "Skip",
                    icon: "arrow.right",
                    isSelected: selected == "skip",
                    style: .secondary
                )
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.29), value: contentVisible)
                .onTapGesture {
                    selectGender("skip")
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            withAnimation {
                contentVisible = true
            }
        }
    }

    private func selectGender(_ value: String) {
        guard selected == nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selected = value
        }
        data.gender = value == "skip" ? nil : value
        analytics.track("onboarding_option_selected", properties: [
            "screen_name": "gender",
            "value": value
        ])
        onSelected()
    }
}

// MARK: - Gender Option

private enum GenderOptionStyle {
    case primary
    case secondary
}

private struct GenderOption: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let style: GenderOptionStyle

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(iconColor)

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(labelColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        if isSelected { return GymScanTheme.accent }
        switch style {
        case .primary: return GymScanTheme.textSecondary
        case .secondary: return GymScanTheme.textSecondary.opacity(0.6)
        }
    }

    private var labelColor: Color {
        if isSelected { return GymScanTheme.accent }
        switch style {
        case .primary: return GymScanTheme.textPrimary.opacity(0.9)
        case .secondary: return GymScanTheme.textSecondary
        }
    }

    private var backgroundColor: Color {
        if isSelected { return GymScanTheme.accent.opacity(0.08) }
        return GymScanTheme.surface
    }

    private var borderColor: Color {
        if isSelected { return GymScanTheme.accent }
        return Color.clear
    }
}
