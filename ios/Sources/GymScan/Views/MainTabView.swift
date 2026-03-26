import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showScanFlow = false
    @State private var scanViewModel = ScanViewModel()
    @State private var workoutViewModel = WorkoutViewModel()

    var initialScanChoice: FirstScanChoice? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case 0:
                    HomeTab(
                        showScanFlow: $showScanFlow,
                        scanViewModel: scanViewModel,
                        workoutViewModel: workoutViewModel
                    )
                case 1:
                    MyGymsTab()
                case 2:
                    HistoryTab()
                case 3:
                    ProfileTab()
                default:
                    HomeTab(
                        showScanFlow: $showScanFlow,
                        scanViewModel: scanViewModel,
                        workoutViewModel: workoutViewModel
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating custom tab bar
            floatingTabBar
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showScanFlow) {
            ScanFlowView(
                scanViewModel: scanViewModel,
                workoutViewModel: workoutViewModel
            )
        }
        .task {
            handleInitialScanChoice()
        }
    }

    // MARK: - Floating Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "house.fill", label: "Home", tag: 0)
            tabBarItem(icon: "building.2.fill", label: "My Gyms", tag: 1)
            tabBarItem(icon: "clock.arrow.circlepath", label: "History", tag: 2)
            tabBarItem(icon: "person.fill", label: "Profile", tag: 3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(GymScanTheme.surface)
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(GymScanTheme.surfaceLight.opacity(0.5), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func tabBarItem(icon: String, label: String, tag: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tag ? GymScanTheme.accent : GymScanTheme.textSecondary)

                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tag ? GymScanTheme.accent : GymScanTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Initial Scan Choice from Onboarding

    private func handleInitialScanChoice() {
        guard let choice = initialScanChoice else { return }
        switch choice {
        case .scanNow:
            scanViewModel.reset()
            workoutViewModel.reset()
            showScanFlow = true
        case .demo:
            scanViewModel.reset()
            workoutViewModel.reset()
            scanViewModel.isDemo = true
            workoutViewModel.isDemo = true
            showScanFlow = true
        }
    }
}
