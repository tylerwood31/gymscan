import SwiftUI

struct EquipmentConfirmationView: View {
    @Bindable var scanViewModel: ScanViewModel
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var isConfirming = false

    var enabledCount: Int {
        scanViewModel.detectedEquipment.filter(\.isEnabled).count
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection

                    equipmentList

                    addButton
                }
                .padding()
            }
            .background(GymScanTheme.background)

            continueButton
        }
        .background(GymScanTheme.background)
        .navigationTitle("Equipment Found")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            AddEquipmentSheet(scanViewModel: scanViewModel)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(GymScanTheme.accentSecondary)

            Text("\(scanViewModel.detectedEquipment.count) items detected")
                .font(.title3.bold())
                .foregroundStyle(GymScanTheme.textPrimary)

            Text("Toggle off items that aren't available, or add any we missed.")
                .font(.subheadline)
                .foregroundStyle(GymScanTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    private var equipmentList: some View {
        VStack(spacing: 8) {
            ForEach(Array(scanViewModel.detectedEquipment.enumerated()), id: \.element.id) { index, equipment in
                EquipmentRow(equipment: equipment) {
                    scanViewModel.detectedEquipment[index].isEnabled.toggle()
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Equipment")
            }
            .font(.subheadline.bold())
            .foregroundStyle(GymScanTheme.accentSecondary)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(GymScanTheme.accentSecondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(GymScanTheme.surfaceLight)
            Button {
                Task {
                    isConfirming = true
                    await scanViewModel.confirmEquipment(modelContext: modelContext)
                    isConfirming = false
                    path.append(ScanFlowStep.muscles)
                }
            } label: {
                HStack {
                    if isConfirming {
                        ProgressView()
                            .tint(GymScanTheme.background)
                    }
                    Text("CONTINUE WITH \(enabledCount) ITEMS")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(GymScanTheme.background)
                .background(
                    enabledCount > 0
                        ? AnyShapeStyle(GymScanTheme.accentGradient)
                        : AnyShapeStyle(Color.gray)
                )
                .clipShape(Capsule())
            }
            .disabled(enabledCount == 0 || isConfirming)
            .padding()
        }
        .background(GymScanTheme.surface)
    }
}

// MARK: - Add Equipment Sheet

struct AddEquipmentSheet: View {
    @Bindable var scanViewModel: ScanViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: EquipmentType = .dumbbell
    @State private var details: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Equipment Type", selection: $selectedType) {
                    ForEach(EquipmentType.allCases) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }

                TextField("Details (e.g., 5-50 lbs)", text: $details)
            }
            .scrollContentBackground(.hidden)
            .background(GymScanTheme.background)
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(GymScanTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let equipment = Equipment(
                            type: selectedType,
                            details: details.isEmpty ? nil : details,
                            confidence: .high,
                            userConfirmed: true,
                            isEnabled: true
                        )
                        scanViewModel.addEquipment(equipment)
                        dismiss()
                    }
                    .foregroundStyle(GymScanTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
