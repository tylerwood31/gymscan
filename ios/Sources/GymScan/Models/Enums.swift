import Foundation

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
    case rowingMachine = "rowing_machine"
    case pullUpBar = "pull_up_bar"
    case resistanceBands = "resistance_bands"
    case kettlebell
    case legPress = "leg_press"
    case latPulldown = "lat_pulldown"
    case pecDeck = "pec_deck"
    case legCurl = "leg_curl"
    case legExtension = "leg_extension"
    case shoulderPress = "shoulder_press"
    case chestPress = "chest_press"
    case medicineBall = "medicine_ball"
    case foamRoller = "foam_roller"
    case yogaMat = "yoga_mat"
    case trx = "trx"
    case battleRopes = "battle_ropes"
    case other

    var id: String { rawValue }

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
        case .rowingMachine: return "Rowing Machine"
        case .pullUpBar: return "Pull-up Bar"
        case .resistanceBands: return "Resistance Bands"
        case .kettlebell: return "Kettlebell"
        case .legPress: return "Leg Press"
        case .latPulldown: return "Lat Pulldown"
        case .pecDeck: return "Pec Deck"
        case .legCurl: return "Leg Curl"
        case .legExtension: return "Leg Extension"
        case .shoulderPress: return "Shoulder Press Machine"
        case .chestPress: return "Chest Press Machine"
        case .medicineBall: return "Medicine Ball"
        case .foamRoller: return "Foam Roller"
        case .yogaMat: return "Yoga Mat"
        case .trx: return "TRX"
        case .battleRopes: return "Battle Ropes"
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
        case .stationaryBike: return "bicycle"
        case .rowingMachine: return "figure.rower"
        case .pullUpBar: return "figure.strengthtraining.traditional"
        case .resistanceBands: return "lines.measurement.horizontal"
        case .kettlebell: return "scalemass.fill"
        case .legPress: return "figure.strengthtraining.functional"
        case .latPulldown: return "arrow.down.to.line"
        case .pecDeck: return "arrow.left.and.right"
        case .legCurl, .legExtension: return "figure.walk"
        case .shoulderPress: return "arrow.up"
        case .chestPress: return "arrow.left.arrow.right"
        case .medicineBall: return "circle.fill"
        case .foamRoller: return "cylinder.fill"
        case .yogaMat: return "rectangle.fill"
        case .trx: return "line.diagonal"
        case .battleRopes: return "wave.3.right"
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
