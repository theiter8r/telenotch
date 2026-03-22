import SwiftUI

enum Theme: String, CaseIterable {
    case midnight
    case warmGlow
    case ocean
    case forest
    case rose

    var name: String {
        switch self {
        case .midnight: return "Midnight"
        case .warmGlow: return "Warm Glow"
        case .ocean:    return "Ocean"
        case .forest:   return "Forest"
        case .rose:     return "Rosé"
        }
    }

    var background: Color {
        switch self {
        case .midnight: return Color(hex: "#1a1a2e")
        case .warmGlow: return Color(hex: "#1c1008")
        case .ocean:    return Color(hex: "#0a1628")
        case .forest:   return Color(hex: "#0d1f0d")
        case .rose:     return Color(hex: "#1f0d14")
        }
    }

    var textColor: Color {
        switch self {
        case .midnight: return Color(hex: "#e0e0ff")
        case .warmGlow: return Color(hex: "#fbbf24")
        case .ocean:    return Color(hex: "#67e8f9")
        case .forest:   return Color(hex: "#86efac")
        case .rose:     return Color(hex: "#f9a8d4")
        }
    }

    var accentColor: Color {
        switch self {
        case .midnight: return Color(hex: "#a78bfa")
        case .warmGlow: return Color(hex: "#f97316")
        case .ocean:    return Color(hex: "#38bdf8")
        case .forest:   return Color(hex: "#34d399")
        case .rose:     return Color(hex: "#fb7185")
        }
    }

    func next() -> Theme {
        let all = Theme.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
