import Foundation
import SwiftUI

enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case dumbbell
    case barbell
    case cableMachine = "cable_machine"
    case smithMachine = "smith_machine"
    case benchFlat = "bench_flat"
    case benchIncline = "bench_incline"
    case benchAdjustable = "bench_adjustable"
    case treadmill
    case elliptical
    case stationaryBike = "stationary_bike"
    case spinBike = "spin_bike"
    case rowingMachine = "rowing_machine"
    case pullUpBar = "pull_up_bar"
    case resistanceBands = "resistance_bands"
    case kettlebell
    case legPress = "leg_press"
    case latPulldown = "lat_pulldown"
    case pecDeck = "pec_deck"
    case legCurl = "leg_curl"
    case legExtension = "leg_extension"
    case shoulderPressMachine = "shoulder_press_machine"
    case chestPressMachine = "chest_press_machine"
    case seatedRow = "seated_row"
    case hackSquat = "hack_squat"
    case preacherCurlBench = "preacher_curl_bench"
    case abBench = "ab_bench"
    case hyperextensionBench = "hyperextension_bench"
    case medicineBall = "medicine_ball"
    case stabilityBall = "stability_ball"
    case foamRoller = "foam_roller"
    case yogaMat = "yoga_mat"
    case trxSuspension = "trx_suspension"
    case battleRopes = "battle_ropes"
    case stairClimber = "stair_climber"
    case functionalTrainer = "functional_trainer"
    case other

    var id: String { rawValue }

    // Custom decoder that falls back to .other for unknown values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = EquipmentType(rawValue: raw) ?? .other
    }

    var displayName: String {
        switch self {
        case .dumbbell: return "Dumbbells"
        case .barbell: return "Barbell"
        case .cableMachine: return "Cable Machine"
        case .smithMachine: return "Smith Machine"
        case .benchFlat: return "Flat Bench"
        case .benchIncline: return "Incline Bench"
        case .benchAdjustable: return "Adjustable Bench"
        case .treadmill: return "Treadmill"
        case .elliptical: return "Elliptical"
        case .stationaryBike: return "Stationary Bike"
        case .spinBike: return "Spin Bike"
        case .rowingMachine: return "Rowing Machine"
        case .pullUpBar: return "Pull-up Bar"
        case .resistanceBands: return "Resistance Bands"
        case .kettlebell: return "Kettlebell"
        case .legPress: return "Leg Press"
        case .latPulldown: return "Lat Pulldown"
        case .pecDeck: return "Pec Deck"
        case .legCurl: return "Leg Curl"
        case .legExtension: return "Leg Extension"
        case .shoulderPressMachine: return "Shoulder Press Machine"
        case .chestPressMachine: return "Chest Press Machine"
        case .seatedRow: return "Seated Row"
        case .hackSquat: return "Hack Squat"
        case .preacherCurlBench: return "Preacher Curl Bench"
        case .abBench: return "Ab Bench"
        case .hyperextensionBench: return "Hyperextension Bench"
        case .medicineBall: return "Medicine Ball"
        case .stabilityBall: return "Stability Ball"
        case .foamRoller: return "Foam Roller"
        case .yogaMat: return "Yoga Mat"
        case .trxSuspension: return "TRX Suspension"
        case .battleRopes: return "Battle Ropes"
        case .stairClimber: return "Stair Climber"
        case .functionalTrainer: return "Functional Trainer"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .dumbbell: return "dumbbell.fill"
        case .barbell: return "dumbbell.fill"
        case .cableMachine: return "arrow.up.and.down.square"
        case .smithMachine: return "square.stack.3d.up"
        case .benchFlat, .benchIncline, .benchAdjustable: return "bed.double.fill"
        case .treadmill: return "figure.run"
        case .elliptical: return "figure.elliptical"
        case .stationaryBike, .spinBike: return "bicycle"
        case .rowingMachine: return "figure.rower"
        case .pullUpBar: return "figure.strengthtraining.traditional"
        case .resistanceBands: return "lines.measurement.horizontal"
        case .kettlebell: return "scalemass.fill"
        case .legPress: return "figure.strengthtraining.functional"
        case .latPulldown: return "arrow.down.to.line"
        case .pecDeck: return "arrow.left.and.right"
        case .legCurl, .legExtension: return "figure.walk"
        case .shoulderPressMachine: return "arrow.up"
        case .chestPressMachine: return "arrow.left.arrow.right"
        case .seatedRow: return "arrow.left"
        case .hackSquat: return "figure.strengthtraining.functional"
        case .preacherCurlBench: return "figure.strengthtraining.traditional"
        case .abBench: return "figure.core.training"
        case .hyperextensionBench: return "figure.flexibility"
        case .medicineBall: return "circle.fill"
        case .stabilityBall: return "circle.dashed"
        case .foamRoller: return "cylinder.fill"
        case .yogaMat: return "rectangle.fill"
        case .trxSuspension: return "line.diagonal"
        case .battleRopes: return "wave.3.right"
        case .stairClimber: return "figure.stairs"
        case .functionalTrainer: return "arrow.up.and.down.square"
        case .other: return "questionmark.circle"
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case legs
    case core
    case fullBody = "full_body"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .legs: return "Legs"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        }
    }

    var iconName: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.strengthtraining.traditional"
        case .triceps: return "figure.strengthtraining.functional"
        case .legs: return "figure.run"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    var tagColor: Color {
        switch self {
        case .chest: return .red
        case .back: return Color(hex: "4ECDC4")    // teal
        case .shoulders: return .orange
        case .biceps: return .purple
        case .triceps: return .pink
        case .legs: return .green
        case .core: return .yellow
        case .fullBody: return Color(hex: "E8A838") // amber
        }
    }
}

enum ConfidenceLevel: String, Codable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "orange"
        case .low: return "red"
        }
    }
}
