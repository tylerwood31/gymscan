import SwiftUI

struct TimerView: View {
    let seconds: Int
    let totalSeconds: Int
    let onSkip: () -> Void

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - seconds) / Double(totalSeconds)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(GymScanTheme.surfaceLight, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(GymScanTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(GymScanTheme.textPrimary)
                        .monospacedDigit()
                    Text("rest")
                        .font(.caption)
                        .foregroundStyle(GymScanTheme.textSecondary)
                }
            }

            Button("Skip") {
                onSkip()
            }
            .font(.subheadline.bold())
            .foregroundStyle(GymScanTheme.textSecondary)
        }
    }

    var timeString: String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        }
        return "\(secs)"
    }
}
