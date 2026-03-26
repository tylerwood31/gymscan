import SwiftUI
import SwiftData

struct HomeTab: View {
    @Binding var showScanFlow: Bool
    @Bindable var scanViewModel: ScanViewModel
    @Bindable var workoutViewModel: WorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Gym.createdAt, order: .reverse) private var gyms: [Gym]
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroScanCard
                    demoScanButton
                    recentGymsSection
                    recentWorkoutsSection

                    // Bottom padding for floating tab bar
                    Color.clear.frame(height: 80)
                }
                .padding()
            }
            .background(GymScanTheme.background)
            .navigationTitle("GymScan")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Hero Scan Card

    private var heroScanCard: some View {
        Button {
            scanViewModel.reset()
            workoutViewModel.reset()
            scanViewModel.isDemo = false
            workoutViewModel.isDemo = false
            showScanFlow = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Hero image
                Group {
                    if let url = Bundle.main.url(forResource: "hero-gym", withExtension: "jpg"),
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 280)
                            .clipped()
                    } else {
                        // Fallback gradient
                        LinearGradient(
                            colors: [GymScanTheme.surfaceLight, GymScanTheme.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 280)
                        .overlay {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(GymScanTheme.accent.opacity(0.5))
                        }
                    }
                }

                // Dark gradient overlay from bottom
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.3),
                        .init(color: GymScanTheme.background.opacity(0.6), location: 0.6),
                        .init(color: GymScanTheme.background.opacity(0.95), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Text overlay at bottom
                VStack(alignment: .leading, spacing: 8) {
                    Text("SCAN A GYM")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text("Point your camera and get a workout")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Demo Button

    private var demoScanButton: some View {
        Button {
            scanViewModel.reset()
            workoutViewModel.reset()
            scanViewModel.isDemo = true
            workoutViewModel.isDemo = true
            showScanFlow = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GymScanTheme.accent)
                Text("TRY A DEMO")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(GymScanTheme.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(GymScanTheme.surface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Gyms

    private var recentGymsSection: some View {
        Group {
            if !gyms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT GYMS")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(GymScanTheme.textSecondary)

                    ForEach(gyms.prefix(5)) { gym in
                        GymRow(gym: gym)
                    }
                }
            }
        }
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        Group {
            if !workouts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT WORKOUTS")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(GymScanTheme.textSecondary)

                    ForEach(workouts.prefix(5)) { workout in
                        WorkoutRow(workout: workout)
                    }
                }
            }
        }
    }
}
