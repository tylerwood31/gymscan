import SwiftUI
import SwiftData

struct ProfileTab: View {
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    fitnessInfoSection
                    subscriptionSection
                    appInfoSection

                    // Bottom padding for floating tab bar
                    Color.clear.frame(height: 80)
                }
                .padding()
            }
            .background(GymScanTheme.background)
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(GymScanTheme.accent.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(GymScanTheme.accent)
            }

            if let profile {
                VStack(spacing: 6) {
                    Text(fitnessLevelDisplay(profile.fitnessLevel).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(GymScanTheme.textPrimary)

                    Text(goalDisplay(profile.travelGoal))
                        .font(.system(size: 15))
                        .foregroundStyle(GymScanTheme.accent)

                    Text("Member since \(profile.createdAt.formatted(.dateTime.month(.wide).year()))")
                        .font(.system(size: 13))
                        .foregroundStyle(GymScanTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(GymScanTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Fitness Info

    private var fitnessInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR PROFILE")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(GymScanTheme.textSecondary)
                .padding(.bottom, 12)

            if let profile {
                let hasAvoidances = !profile.movementsToAvoid.isEmpty
                let hasActivities = !profile.preferredActivities.isEmpty

                settingsRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Fitness Level",
                    value: fitnessLevelDisplay(profile.fitnessLevel),
                    isFirst: true,
                    isLast: !hasActivities && !hasAvoidances
                )

                if hasActivities {
                    settingsRow(
                        icon: "heart.fill",
                        title: "Activities",
                        value: profile.preferredActivities.map { activityDisplay($0) }.joined(separator: ", ")
                    )
                }

                settingsRow(
                    icon: "target",
                    title: "Travel Goal",
                    value: goalDisplay(profile.travelGoal),
                    isLast: !hasAvoidances
                )

                if hasAvoidances {
                    settingsRow(
                        icon: "exclamationmark.triangle",
                        title: "Avoidances",
                        value: profile.movementsToAvoid.map { avoidanceDisplay($0) }.joined(separator: ", "),
                        isLast: true
                    )
                }
            } else {
                Text("Complete onboarding to set up your profile.")
                    .font(.system(size: 15))
                    .foregroundStyle(GymScanTheme.textSecondary)
                    .padding(16)
            }
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        value: String,
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(GymScanTheme.accent)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(GymScanTheme.textSecondary)
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(GymScanTheme.textPrimary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GymScanTheme.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(GymScanTheme.surface)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(GymScanTheme.surfaceLight.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 54)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: isFirst ? 14 : 0,
                bottomLeadingRadius: isLast ? 14 : 0,
                bottomTrailingRadius: isLast ? 14 : 0,
                topTrailingRadius: isFirst ? 14 : 0
            )
        )
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            // Current plan
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT PLAN")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(GymScanTheme.textSecondary)
                    Text("Free")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(GymScanTheme.textPrimary)
                }
                Spacer()
                Text("Free")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(GymScanTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GymScanTheme.accent.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Premium features teaser
            VStack(alignment: .leading, spacing: 10) {
                premiumFeatureRow(icon: "building.2.fill", text: "Save unlimited gyms")
                premiumFeatureRow(icon: "clock.arrow.circlepath", text: "Full workout history")
                premiumFeatureRow(icon: "flame.fill", text: "Consistency streaks")
            }

            // Upgrade CTA
            Button {
                // Paywall action (placeholder)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("UPGRADE TO PREMIUM")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundStyle(GymScanTheme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(GymScanTheme.accentGradient)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(GymScanTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(GymScanTheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(GymScanTheme.textSecondary)
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 6) {
            Text("GymScan v1.0.0")
                .font(.system(size: 13))
                .foregroundStyle(GymScanTheme.textSecondary)

            Text("Built for travelers who train.")
                .font(.system(size: 12))
                .foregroundStyle(GymScanTheme.textSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Display Formatters

    private func fitnessLevelDisplay(_ level: String) -> String {
        switch level {
        case "beginner": return "Beginner"
        case "intermediate": return "Intermediate"
        case "consistent": return "Consistent"
        case "advanced": return "Advanced"
        default: return level.capitalized
        }
    }

    private func activityDisplay(_ activity: String) -> String {
        switch activity {
        case "strength": return "Strength"
        case "cardio": return "Cardio"
        case "hiit": return "HIIT"
        case "yoga": return "Yoga"
        case "anything": return "Anything"
        default: return activity.capitalized
        }
    }

    private func goalDisplay(_ goal: String) -> String {
        switch goal {
        case "feel_good": return "Feel Good"
        case "maintain": return "Maintain"
        case "push": return "Push Harder"
        default: return goal.capitalized
        }
    }

    private func avoidanceDisplay(_ avoidance: String) -> String {
        switch avoidance {
        case "heavy_barbell": return "Heavy Barbell"
        case "jumping": return "Jumping"
        case "overhead": return "Overhead"
        case "running": return "Running"
        default: return avoidance.capitalized
        }
    }
}
