import Foundation
import SwiftData
import UIKit

@Observable
@MainActor
final class ScanViewModel {
    var scanState: ScanState = .idle
    var detectedEquipment: [Equipment] = []
    var currentGymId: String?
    var currentGym: Gym?
    var error: String?
    var frameExtractionProgress: String = ""
    var isDemo: Bool = false

    enum ScanState {
        case idle
        case recording
        case extractingFrames
        case uploading
        case processing
        case complete
        case error
    }

    private let apiClient = APIClient.shared

    func processVideo(at url: URL, modelContext: ModelContext) async {
        do {
            scanState = .extractingFrames
            frameExtractionProgress = "Extracting frames from video..."

            let frames = try await VideoProcessor.extractFrames(from: url)
            frameExtractionProgress = "Extracted \(frames.count) frames"

            await processFrames(frames, modelContext: modelContext)

            // Clean up temp video file
            try? FileManager.default.removeItem(at: url)
        } catch {
            self.error = error.localizedDescription
            scanState = .error
        }
    }

    /// Process raw image data frames through the scan API.
    /// Used by both the camera flow and demo mode.
    func processFrames(_ frames: [Data], modelContext: ModelContext) async {
        do {
            scanState = .uploading
            frameExtractionProgress = "Analyzing gym equipment..."

            let response = try await apiClient.scanEquipment(frames: frames)
            currentGymId = response.gymId

            let gym = Gym(id: UUID(uuidString: response.gymId) ?? UUID())
            let equipmentList = response.equipment.map { item in
                Equipment(
                    type: EquipmentType(rawValue: item.type) ?? .other,
                    details: item.details.isEmpty ? nil : item.details,
                    confidence: ConfidenceLevel(rawValue: item.confidence) ?? .medium,
                    isEnabled: true
                )
            }
            gym.equipment = equipmentList

            // Don't persist demo scans to SwiftData
            if !isDemo {
                modelContext.insert(gym)
                try modelContext.save()
            }

            currentGym = gym
            detectedEquipment = equipmentList
            scanState = .complete
        } catch {
            self.error = error.localizedDescription
            scanState = .error
        }
    }

    func confirmEquipment(modelContext: ModelContext) async {
        guard let gymId = currentGymId else { return }

        let confirmed = detectedEquipment.filter(\.isEnabled).map { item in
            EquipmentConfirmationDTO(
                type: item.typeRaw,
                details: item.details ?? "",
                userConfirmed: true
            )
        }

        do {
            _ = try await apiClient.confirmEquipment(gymId: gymId, equipment: confirmed)

            if let gym = currentGym {
                gym.equipment = detectedEquipment.filter(\.isEnabled)
                try modelContext.save()
            }
        } catch {
            // Non-critical -- we still have the local equipment list
            self.error = error.localizedDescription
        }
    }

    func addEquipment(_ equipment: Equipment) {
        detectedEquipment.append(equipment)
    }

    func reset() {
        scanState = .idle
        detectedEquipment = []
        currentGymId = nil
        currentGym = nil
        error = nil
        frameExtractionProgress = ""
    }
}
