import SwiftUI

/// Design tokens from style.css `:root`, ported as one theme.
enum Theme {
    static let bg = Color(hex: "#0E1018")
    static let bg2 = Color(hex: "#141724")
    static let glass = Color.white.opacity(0.065)
    static let glass2 = Color.white.opacity(0.10)
    static let line = Color.white.opacity(0.10)
    static let text = Color(hex: "#F4F5F8")
    static let muted = Color(hex: "#A9AEBD")
    static let dim = Color(hex: "#6E7385")
    static let violet = Color(hex: "#9C8CFF")
    static let violetDeep = Color(hex: "#7C6CF0")
    static let coral = Color(hex: "#FF6B4A")
    static let mint = Color(hex: "#4ADE80")
    static let amber = Color(hex: "#F5B544")
    /// body copy on dark (`.p`, `.sub`)
    static let soft = Color(hex: "#D5D8E1")

    /// Ring colours `KC`
    static func ring(_ k: String) -> Color { k == "m" ? violet : k == "h" ? coral : mint }

    enum Radius {
        static let card: CGFloat = 24
        static let button: CGFloat = 28
        static let buttonSmall: CGFloat = 22
        static let chip: CGFloat = 99
    }
    enum Size {
        static let h1: CGFloat = 34
        static let title2: CGFloat = 24
        static let name: CGFloat = 16
        static let meta: CGFloat = 13
        static let small: CGFloat = 12
        static let label: CGFloat = 11
        static let body: CGFloat = 14
        static let button: CGFloat = 16
        static let buttonHeight: CGFloat = 56
        static let buttonSmallHeight: CGFloat = 44
    }
    /// Page width cap (`#app{max-width:480px}`) and gutters
    static let maxWidth: CGFloat = 480
    static let gutter: CGFloat = 16
}

extension Color {
    init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(.sRGB, red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255, opacity: 1)
    }
}

/// The web's font: Inter 400/500/600/700/800 (bundled from fonts.css), fixed size like the CSS.
extension Font {
    static func inter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let face: String
        switch weight {
        case .heavy, .black: face = "ExtraBold"
        case .bold: face = "Bold"
        case .semibold: face = "SemiBold"
        case .medium: face = "Medium"
        default: face = "Regular"
        }
        return .custom("Inter-" + face, fixedSize: size)
    }
}
