import SwiftUI

struct FirstScanPromptScreen: View {
    var onChoice: (FirstScanChoice) -> Void

    @State private var contentVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Headline
            Text("Let's find\nyour workout.")
                .font(.system(size: 34, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(GymScanTheme.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: contentVisible)
                .padding(.bottom, 16)

            // How it works — 3 steps
            VStack(alignment: .leading, spacing: 14) {
                stepRow(number: "1", icon: "camera.viewfinder", text: "Scan any gym with your camera")
                stepRow(number: "2", icon: "checklist", text: "We identify every piece of equipment")
                stepRow(number: "3", icon: "figure.strengthtraining.traditional", text: "Get a workout built for you")
            }
            .padding(.horizontal, 32)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.5).delay(0.25), value: contentVisible)

            Spacer()

            VStack(spacing: 14) {
                // Primary: Scan a gym now
                Button {
                    onChoice(.scanNow)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("SCAN A GYM NOW")
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
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: contentVisible)

                // Secondary: Try a demo
                Button {
                    onChoice(.demo)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("TRY A DEMO FIRST")
                            .font(.system(size: 15, weight: .bold))
                            .tracking(1.5)
                    }
                    .foregroundStyle(GymScanTheme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(GymScanTheme.surface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.45), value: contentVisible)
            }
            .padding(.horizontal, 24)

            Text("You can always scan later from the home screen")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(GymScanTheme.textSecondary.opacity(0.7))
                .padding(.top, 20)
                .padding(.bottom, 48)
                .opacity(contentVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.55), value: contentVisible)
        }
        .onAppear {
            withAnimation {
                contentVisible = true
            }
        }
    }

    private func stepRow(number: String, icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(GymScanTheme.background)
                .frame(width: 28, height: 28)
                .background(GymScanTheme.accent)
                .clipShape(Circle())

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(GymScanTheme.accent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(GymScanTheme.textPrimary)
        }
    }
}
