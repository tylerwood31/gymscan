import SwiftUI

enum GymScanTheme {
    // MARK: - Colors
    static let background = Color(hex: "0E0E12")
    static let surface = Color(hex: "1C1C24")
    static let surfaceLight = Color(hex: "2A2A36")
    static let accent = Color(hex: "E8A838")       // amber/gold
    static let accentSecondary = Color(hex: "4ECDC4") // teal
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "8E8E93")
    static let destructive = Color(hex: "E85454")

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "E8A838"), Color(hex: "D4952E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceGradient = LinearGradient(
        colors: [Color(hex: "1C1C24"), Color(hex: "16161E")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
