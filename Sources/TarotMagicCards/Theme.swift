import SwiftUI

enum Theme {
    static let background = Color(hex: "#01050D")
    static let accentRed = Color(hex: "#C20000")
    static let glassBackground = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.1)
    static let glassBorderHighlight = Color.white.opacity(0.2)
    static let secondaryText = Color.white.opacity(0.5)

    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#02060E"), Color(hex: "#C20000")],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
