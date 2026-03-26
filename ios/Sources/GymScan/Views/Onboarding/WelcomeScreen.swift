import SwiftUI

struct WelcomeScreen: View {
    var onContinue: () -> Void

    @State private var logoOpacity: Double = 0
    @State private var headlineOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gym image with dark overlay
            Group {
                if let url = Bundle.main.url(forResource: "welcome-gym", withExtension: "jpg"),
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                }
            }
            LinearGradient(
                colors: [
                    GymScanTheme.background.opacity(0.3),
                    GymScanTheme.background.opacity(0.85),
                    GymScanTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Text("GymScan")
                    .font(.system(size: 44, weight: .bold, design: .default))
                    .tracking(-1.0)
                    .foregroundStyle(GymScanTheme.accentGradient)
                    .opacity(logoOpacity)
                    .padding(.bottom, 32)

                // Headline
                VStack(spacing: 8) {
                    Text("Scan any gym.")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .tracking(-0.5)
                        .foregroundStyle(GymScanTheme.textPrimary)

                    Text("Get a workout in seconds.")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .tracking(-0.5)
                        .foregroundStyle(GymScanTheme.textPrimary)
                }
                .multilineTextAlignment(.center)
                .opacity(headlineOpacity)
                .padding(.bottom, 20)

                // Subtitle
                Text("Point your camera at any gym. We'll identify\nthe equipment and build you a personalized workout.")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(GymScanTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(subtitleOpacity)

                Spacer()

                // Get Started button
                Button(action: onContinue) {
                    Text("GET STARTED")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(GymScanTheme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(GymScanTheme.accentGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .opacity(buttonOpacity)
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                headlineOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                buttonOpacity = 1
            }
        }
    }
}
