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

    // MARK: - Skeuomorphic Tactile Palette
    static let paperLight = Color(red: 0xF4 / 255.0, green: 0xF1 / 255.0, blue: 0xEA / 255.0)
    static let paperDark = Color(red: 0xEA / 255.0, green: 0xE5 / 255.0, blue: 0xD9 / 255.0)

    static let cardTop = Color(red: 0xFA / 255.0, green: 0xF8 / 255.0, blue: 0xF3 / 255.0)
    static let cardBottom = Color(red: 0xEF / 255.0, green: 0xEC / 255.0, blue: 0xE4 / 255.0)

    static let wellTop = Color(red: 0xDD / 255.0, green: 0xD9 / 255.0, blue: 0xCE / 255.0)
    static let wellBottom = Color(red: 0xEB / 255.0, green: 0xE7 / 255.0, blue: 0xDE / 255.0)

    static let cobaltLight = Color(red: 0x25 / 255.0, green: 0x52 / 255.0, blue: 0xD6 / 255.0)
    static let cobaltDeep = Color(red: 0x15 / 255.0, green: 0x2E / 255.0, blue: 0x82 / 255.0)

    static let charcoalLight = Color(red: 0x2A / 255.0, green: 0x29 / 255.0, blue: 0x2B / 255.0)
    static let charcoalDark = Color(red: 0x14 / 255.0, green: 0x13 / 255.0, blue: 0x14 / 255.0)

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

// MARK: - Skeuomorphic Tactile Gradients

extension LinearGradient {
    static let paperGroundGradient = LinearGradient(
        colors: [Color.paperLight, Color.paperDark],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [Color.cardTop, Color.cardBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let wellGradient = LinearGradient(
        colors: [Color.wellTop, Color.wellBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cobaltEnamel = LinearGradient(
        colors: [Color.cobaltLight, Color.cobaltBlue, Color.cobaltDeep],
        startPoint: .top,
        endPoint: .bottom
    )

    static let charcoalGradient = LinearGradient(
        colors: [Color.charcoalLight, Color.charcoalDark],
        startPoint: .top,
        endPoint: .bottom
    )

    static let topLightBevel = LinearGradient(
        colors: [Color.white.opacity(0.85), Color.black.opacity(0.12)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let reverseBevel = LinearGradient(
        colors: [Color.black.opacity(0.18), Color.white.opacity(0.75)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let goldGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.898, blue: 0.498), Color(red: 0.831, green: 0.686, blue: 0.216), Color(red: 0.667, green: 0.478, blue: 0.118)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let silverGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 1.0, blue: 1.0), Color(red: 0.839, green: 0.839, blue: 0.839), Color(red: 0.620, green: 0.620, blue: 0.620)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let bronzeGradient = LinearGradient(
        colors: [Color(red: 0.976, green: 0.812, blue: 0.675), Color(red: 0.804, green: 0.498, blue: 0.196), Color(red: 0.549, green: 0.294, blue: 0.094)],
        startPoint: .top,
        endPoint: .bottom
    )
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

// MARK: - Hairline & Engraved Divider

struct HairlineDivider: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1 / max(displayScale, 1.0))
    }
}

/// A tactile engraved physical divider with a 1px top dark line and 1px bottom specular reflection.
struct EngravedDivider: View {
    var body: some View {
        VStack(spacing: 0) {
            Color.black.opacity(0.12)
                .frame(height: 1)
            Color.white.opacity(0.75)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Paper Grain Procedural Texture

struct PaperGrainView: View {
    var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let seed = Int((x * 73 + y * 97).truncatingRemainder(dividingBy: 17))
                    if seed == 3 || seed == 11 {
                        let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                        context.fill(Path(rect), with: .color(Color.black.opacity(0.022)))
                    } else if seed == 7 {
                        let rect = CGRect(x: x, y: y, width: 1.0, height: 1.0)
                        context.fill(Path(rect), with: .color(Color.white.opacity(0.040)))
                    }
                    y += 4
                }
                x += 4
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Skeuomorphic Card Modifier

struct SkeuomorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.cardGradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                // 1pt beveled top-light / bottom-dark rim
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LinearGradient.topLightBevel, lineWidth: 1)
            )
            .overlay(
                // Crisp top specular highlight rim
                VStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.white.opacity(0.65), lineWidth: 1)
                        .frame(height: cornerRadius)
                        .mask(
                            VStack {
                                Rectangle().frame(height: 2)
                                Spacer()
                            }
                        )
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .allowsHitTesting(false)
            )
            // Two-layer realistic drop shadow: tight contact + soft ambient
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color(red: 0x36 / 255.0, green: 0x30 / 255.0, blue: 0x24 / 255.0).opacity(0.09), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Skeuomorphic Recessed Well Modifier

struct SkeuomorphicWellModifier: ViewModifier {
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.wellGradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                // Reverse bevel: dark top lip + bright bottom lip
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color.black.opacity(0.18), Color.clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 3)
                    Spacer()
                    Color.white.opacity(0.85)
                        .frame(height: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LinearGradient.reverseBevel, lineWidth: 1)
            )
    }
}

// MARK: - Skeuomorphic Cobalt Button Modifier

struct SkeuomorphicCobaltButtonModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.cobaltEnamel)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                // Top specular crescent / shine
                VStack {
                    LinearGradient(colors: [Color.white.opacity(0.55), Color.clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.60), Color.black.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.20), radius: 2, x: 0, y: 1)
            .shadow(color: Color.cobaltBlue.opacity(0.40), radius: 7, x: 0, y: 3)
    }
}

// MARK: - Letterpress Text Modifier

struct LetterpressModifier: ViewModifier {
    var isLight: Bool = false

    func body(content: Content) -> some View {
        if isLight {
            // Light text on cobalt / charcoal: top dark shadow
            content
                .shadow(color: Color.black.opacity(0.55), radius: 0.5, x: 0, y: -0.75)
        } else {
            // Dark text on paper / card: bottom white shadow
            content
                .shadow(color: Color.white.opacity(0.80), radius: 0.5, x: 0, y: 0.75)
        }
    }
}

// MARK: - Skeuomorphic Button Style

struct SkeuomorphicButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.snappySpring, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed)
    }
}

// MARK: - View Extension Helpers

extension View {
    func skeuomorphicCard(cornerRadius: CGFloat = 14) -> some View {
        modifier(SkeuomorphicCardModifier(cornerRadius: cornerRadius))
    }

    func skeuomorphicWell(cornerRadius: CGFloat = 10) -> some View {
        modifier(SkeuomorphicWellModifier(cornerRadius: cornerRadius))
    }

    func skeuomorphicCobaltButton(cornerRadius: CGFloat = 12) -> some View {
        modifier(SkeuomorphicCobaltButtonModifier(cornerRadius: cornerRadius))
    }

    func letterpress(isLight: Bool = false) -> some View {
        modifier(LetterpressModifier(isLight: isLight))
    }

    /// Renders the skeuomorphic textured warm linen paper background with subtle grain.
    func paperBackground() -> some View {
        self.background {
            ZStack {
                LinearGradient.paperGroundGradient
                    .ignoresSafeArea()
                PaperGrainView()
            }
        }
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
            .font(hostGrotesk(.semibold, size: 12))
            .letterpress(isLight: true)
            .foregroundStyle(Color.inverseText)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(LinearGradient.charcoalGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 1.5, x: 0, y: 1)
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
