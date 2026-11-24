import SwiftUI

// MARK: - Design Tokens: Colors

extension Color {
    /// Warm paper background (#FBFAF4)
    static let pageGround = Color(red: 0xFB / 255.0, green: 0xFA / 255.0, blue: 0xF4 / 255.0)
    /// Inset card surface (#F2F1EC)
    static let cardSurface = Color(red: 0xF2 / 255.0, green: 0xF1 / 255.0, blue: 0xEC / 255.0)
    /// Primary text (#000000)
    static let primaryText = Color(red: 0x00 / 255.0, green: 0x00 / 255.0, blue: 0x00 / 255.0)
    /// Secondary text (#414141)
    static let secondaryText = Color(red: 0x41 / 255.0, green: 0x41 / 255.0, blue: 0x41 / 255.0)
    /// Muted text (#595858)
    static let mutedText = Color(red: 0x59 / 255.0, green: 0x58 / 255.0, blue: 0x58 / 255.0)
    /// Dark chips / badges (#141314)
    static let inverseSurface = Color(red: 0x14 / 255.0, green: 0x13 / 255.0, blue: 0x14 / 255.0)
    /// Inverse text on dark surface (#FCFCFD)
    static let inverseText = Color(red: 0xFC / 255.0, green: 0xFC / 255.0, blue: 0xFD / 255.0)
    /// Brand accent Cobalt Blue (#1E40AF)
    static let cobaltBlue = Color(red: 0x1E / 255.0, green: 0x40 / 255.0, blue: 0xAF / 255.0)
    /// Label on cobalt accent (#FCFCFD)
    static let cobaltLabel = Color(red: 0xFC / 255.0, green: 0xFC / 255.0, blue: 0xFD / 255.0)
    /// Ruled dividers (#DCDBD5)
    static let hairline = Color(red: 0xDC / 255.0, green: 0xDB / 255.0, blue: 0xD5 / 255.0)
}

extension ShapeStyle where Self == Color {
    static var pageGround: Color { Color.pageGround }
    static var cardSurface: Color { Color.cardSurface }
    static var primaryText: Color { Color.primaryText }
    static var secondaryText: Color { Color.secondaryText }
    static var mutedText: Color { Color.mutedText }
    static var inverseSurface: Color { Color.inverseSurface }
    static var inverseText: Color { Color.inverseText }
    static var cobaltBlue: Color { Color.cobaltBlue }
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

    // Try custom font first; fallback to system font with matched weight
    if UIFont(name: name, size: size) != nil {
        return .custom(name, size: size, relativeTo: .body)
    }
    return .system(size: size, weight: weight)
}

extension Font {
    /// Host Grotesk font helper on Font
    static func hostGrotesk(_ weight: Font.Weight, size: CGFloat) -> Font {
        HabitTrackerTheme.hostGroteskFont(weight, size: size)
    }
}

extension Font.Weight {
    /// Alias for `.semibold`
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
            .font(hostGrotesk(.medium, size: 32))
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

// MARK: - Hairline Divider

struct HairlineDivider: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1 / max(displayScale, 1.0))
    }
}

// MARK: - Inset Card Modifier

struct InsetCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func insetCard() -> some View {
        modifier(InsetCardModifier())
    }
}

// MARK: - Inverse Badge

struct InverseBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(hostGrotesk(.semibold, size: 13))
            .foregroundStyle(Color.inverseText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.inverseSurface)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Animation Helpers

extension Animation {
    static let snappySpring = Animation.spring(response: 0.28, dampingFraction: 0.85)
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
