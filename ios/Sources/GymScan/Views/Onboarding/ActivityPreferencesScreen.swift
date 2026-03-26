import SwiftUI

struct ActivityPreferencesScreen: View {
    var data: OnboardingData
    var onContinue: () -> Void

    @State private var pillsVisible = false

    private let analytics = AnalyticsService.shared

    private let activities: [(id: String, label: String)] = [
        ("strength", "Strength"),
        ("cardio", "Cardio"),
        ("hiit", "HIIT"),
        ("yoga", "Yoga & stretching"),
        ("anything", "A bit of everything"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text("What do you enjoy?")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .padding(.bottom, 8)

            Text("Select all that apply")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(GymScanTheme.textSecondary)
                .padding(.bottom, 40)

            // Flowing pill layout
            FlowLayout(spacing: 10) {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                    let isSelected = data.preferredActivities.contains(activity.id)
                    ActivityPill(label: activity.label, isSelected: isSelected)
                        .opacity(pillsVisible ? 1 : 0)
                        .offset(y: pillsVisible ? 0 : 15)
                        .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.06), value: pillsVisible)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if data.preferredActivities.contains(activity.id) {
                                    data.preferredActivities.remove(activity.id)
                                } else {
                                    data.preferredActivities.insert(activity.id)
                                }
                            }
                            analytics.track("onboarding_option_selected", properties: [
                                "screen_name": "activity_preferences",
                                "value": activity.id
                            ])
                        }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("CONTINUE")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(data.preferredActivities.isEmpty ? GymScanTheme.textSecondary : GymScanTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        data.preferredActivities.isEmpty
                            ? AnyShapeStyle(GymScanTheme.surface)
                            : AnyShapeStyle(GymScanTheme.accentGradient)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(data.preferredActivities.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation {
                pillsVisible = true
            }
        }
    }
}

// MARK: - Activity Pill

private struct ActivityPill: View {
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct ArrangementResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return ArrangementResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: totalWidth, height: currentY + lineHeight)
        )
    }
}
