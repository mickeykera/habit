import SwiftUI

// MARK: - Design Tokens: Colors

extension Color {
    /// Crisp White page background (#FFFFFF)
    static let pageGround = Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    /// Flat neutral card / alternate surface (#F7F6F6)
    static let cardSurface = Color(red: 0xF7 / 255.0, green: 0xF6 / 255.0, blue: 0xF6 / 255.0)
    /// Primary text (#201F20)
    static let primaryText = Color(red: 0x20 / 255.0, green: 0x1F / 255.0, blue: 0x20 / 255.0)
    /// Secondary text (#494949)
    static let secondaryText = Color(red: 0x49 / 255.0, green: 0x49 / 255.0, blue: 0x49 / 255.0)
    /// Muted text (#606060)
    static let mutedText = Color(red: 0x60 / 255.0, green: 0x60 / 255.0, blue: 0x60 / 255.0)
    /// Inverse surface for active dark badges/chips (#141314)
    static let inverseSurface = Color(red: 0x14 / 255.0, green: 0x13 / 255.0, blue: 0x14 / 255.0)
    /// Inverse text on dark surface (#FCFCFD)
    static let inverseText = Color(red: 0xFC / 255.0, green: 0xFC / 255.0, blue: 0xFD / 255.0)
    /// Brand & primary action accent Electric Royal Blue (#2E5BFF)
    static let cobaltBlue = Color(red: 0x2E / 255.0, green: 0x5B / 255.0, blue: 0xFF / 255.0)
    static let royalBlue = Color(red: 0x2E / 255.0, green: 0x5B / 255.0, blue: 0xFF / 255.0)
    /// Label on royal blue accent (#FCFCFD)
    static let cobaltLabel = Color(red: 0xFC / 255.0, green: 0xFC / 255.0, blue: 0xFD / 255.0)
    /// Subtle hairline for controls/inputs (#E0E0DF)
    static let hairline = Color(red: 0xE0 / 255.0, green: 0xE0 / 255.0, blue: 0xDF / 255.0)

    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch clean.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
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

// MARK: - ShapeStyle Extensions for Swift 6 Concurrency

extension ShapeStyle where Self == Color {
    static var pageGround: Color { Color.pageGround }
    static var cardSurface: Color { Color.cardSurface }
    static var primaryText: Color { Color.primaryText }
    static var secondaryText: Color { Color.secondaryText }
    static var mutedText: Color { Color.mutedText }
    static var inverseSurface: Color { Color.inverseSurface }
    static var inverseText: Color { Color.inverseText }
    static var cobaltBlue: Color { Color.cobaltBlue }
    static var royalBlue: Color { Color.royalBlue }
    static var cobaltLabel: Color { Color.cobaltLabel }
    static var hairline: Color { Color.hairline }
}

// MARK: - Typography: Host Grotesk

/// Returns a Host Grotesk font at the given weight and size, falling back to
/// the system font if the custom font is unavailable.
func hostGrotesk(_ weight: Font.Weight, size: CGFloat) -> Font {
    let name: String
    switch weight {
    case .bold:
        name = "HostGrotesk-Bold"
    case .semibold:
        name = "HostGrotesk-SemiBold"
    case .medium:
        name = "HostGrotesk-Medium"
    default:
        name = "HostGrotesk-Regular"
    }

    if UIFont(name: name, size: size) != nil {
        return .custom(name, size: size, relativeTo: .body)
    }
    return .system(size: size, weight: weight)
}

extension Font {
    static func hostGrotesk(_ weight: Font.Weight, size: CGFloat) -> Font {
        HabitTrackerTheme.hostGroteskFont(weight, size: size)
    }
}

extension Font.Weight {
    static let semiBold: Font.Weight = .semibold
}

private enum HabitTrackerTheme {
    static func hostGroteskFont(_ weight: Font.Weight, size: CGFloat) -> Font {
        hostGrotesk(weight, size: size)
    }
}

// MARK: - Typography View Modifiers

struct DisplayHeadingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(hostGrotesk(.medium, size: 34))
            .foregroundStyle(Color.primaryText)
            .tracking(-0.5)
    }
}

struct BodyTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(hostGrotesk(.regular, size: 16))
            .foregroundStyle(Color.primaryText)
    }
}

struct LabelTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(hostGrotesk(.medium, size: 13))
            .foregroundStyle(Color.mutedText)
    }
}

struct TabularNumbersModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.monospacedDigit()
    }
}

extension View {
    func displayHeading() -> some View {
        modifier(DisplayHeadingModifier())
    }

    func bodyText() -> some View {
        modifier(BodyTextModifier())
    }

    func labelText() -> some View {
        modifier(LabelTextModifier())
    }

    func tabularNumbers() -> some View {
        modifier(TabularNumbersModifier())
    }
}

// MARK: - Flat Surface & Card Modifiers

struct FlatCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 8
    var borderColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1)
                }
            }
    }
}

extension View {
    func flatCard(cornerRadius: CGFloat = 8, borderColor: Color? = nil) -> some View {
        modifier(FlatCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }

    /// Compatibility helper: transforms any leftover skeuomorphic card call into flat minimal card
    func skeuomorphicCard(cornerRadius: CGFloat = 8) -> some View {
        flatCard(cornerRadius: cornerRadius)
    }

    /// Compatibility helper: transforms any leftover skeuomorphic well call into flat card
    func skeuomorphicWell(cornerRadius: CGFloat = 8) -> some View {
        flatCard(cornerRadius: cornerRadius)
    }

    /// Flat cobalt pill/rounded button helper
    func skeuomorphicCobaltButton(cornerRadius: CGFloat = 9999) -> some View {
        self
            .background(Color.cobaltBlue)
            .clipShape(Capsule())
    }

    /// Letterpress helper: cleanly transparent (no shadows in flat design)
    func letterpress(isLight: Bool = false) -> some View {
        self
    }

    /// Flat White background
    func paperBackground() -> some View {
        self.background(Color.pageGround.ignoresSafeArea())
    }
}

// MARK: - Inset Card Modifier (Flat)

struct InsetCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    func insetCard() -> some View {
        modifier(InsetCardModifier())
    }
}

// MARK: - Inverse Badge (Flat Charcoal Pill)

struct InverseBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(hostGrotesk(.semibold, size: 11))
            .foregroundStyle(Color.inverseText)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.inverseSurface)
            .clipShape(Capsule())
    }
}

// MARK: - Pill Button Style

struct AppPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.snappySpring, value: configuration.isPressed)
    }
}

/// Compatibility alias
typealias SkeuomorphicButtonStyle = AppPillButtonStyle

// MARK: - Animation & Haptics Helpers

extension Animation {
    /// Snappy spring response: 0.25, dampingFraction: 0.88
    static let snappySpring = Animation.spring(response: 0.25, dampingFraction: 0.88)
}

struct HabitCompletionFeedbackModifier<V: Equatable>: ViewModifier {
    let trigger: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .sensoryFeedback(.impact, trigger: trigger)
        }
    }
}

extension View {
    func habitCompletionFeedback<V: Equatable>(trigger: V) -> some View {
        modifier(HabitCompletionFeedbackModifier(trigger: trigger))
    }
}
