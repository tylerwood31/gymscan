import SwiftUI

struct MyGymsTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                GymScanTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                    Spacer()

                    // Lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(GymScanTheme.textSecondary)

                    // Title with divider
                    VStack(spacing: 14) {
                        Text("MY GYMS")
                            .font(.system(size: 22, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(GymScanTheme.textPrimary)

                        Rectangle()
                            .fill(GymScanTheme.accent)
                            .frame(width: 40, height: 2)
                    }

                    // Description
                    VStack(spacing: 6) {
                        Text("Save gyms you visit.")
                            .foregroundStyle(GymScanTheme.textSecondary)
                        Text("Never re-scan a hotel you've been to.")
                            .foregroundStyle(GymScanTheme.textSecondary)
                    }
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)

                    // CTA Button
                    Button {
                        // Navigate to scan flow
                    } label: {
                        Text("COMPLETE YOUR FIRST SCAN")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(GymScanTheme.background)
                            .frame(maxWidth: 300)
                            .frame(height: 56)
                            .background(GymScanTheme.accentGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    // Sub-text
                    Text("Complete a scan to unlock all features.")
                        .font(.system(size: 13))
                        .foregroundStyle(GymScanTheme.textSecondary.opacity(0.7))

                    Spacer()
                    Spacer()
                    Spacer()

                    // Bottom padding for floating tab bar
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("My Gyms")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
