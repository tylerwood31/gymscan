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

            continueButton
        }
        .navigationTitle("Equipment Found")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddSheet) {
            AddEquipmentSheet(scanViewModel: scanViewModel)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("\(scanViewModel.detectedEquipment.count) items detected")
                .font(.title3.bold())

            Text("Toggle off items that aren't available, or add any we missed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
            .foregroundStyle(.blue)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Divider()
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
                            .tint(.white)
                    }
                    Text("Continue with \(enabledCount) items")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(.white)
                .background(enabledCount > 0 ? .blue : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(enabledCount == 0 || isConfirming)
            .padding()
        }
        .background(.regularMaterial)
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
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                }
            }
        }
        .presentationDetents([.medium])
    }
}
