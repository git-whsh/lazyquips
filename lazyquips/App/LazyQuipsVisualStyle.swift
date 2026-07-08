import SwiftUI

enum LazyQuipsVisualStyle {
    static let carbonCopyPurpleRed: Double = 97.0 / 255.0
    static let carbonCopyPurpleGreen: Double = 85.0 / 255.0
    static let carbonCopyPurpleBlue: Double = 245.0 / 255.0
    static let carbonCopyPurple = Color(
        red: carbonCopyPurpleRed,
        green: carbonCopyPurpleGreen,
        blue: carbonCopyPurpleBlue
    )
    static let accentForegroundLightRed: Double = 79.0 / 255.0
    static let accentForegroundLightGreen: Double = 70.0 / 255.0
    static let accentForegroundLightBlue: Double = 229.0 / 255.0
    static let accentForegroundDarkRed: Double = 215.0 / 255.0
    static let accentForegroundDarkGreen: Double = 211.0 / 255.0
    static let accentForegroundDarkBlue: Double = 255.0 / 255.0
    static let rowSelectedBackground = carbonCopyPurple
    static let rowHoverBackground = carbonCopyPurple.opacity(0.12)
    static let rowDivider = Color.primary.opacity(0.08)
    static let rowBoundary = Color.primary.opacity(0.1)
    static let copiedBadgeReservedWidth: CGFloat = 86
    static let copiedBadgeTrailingPadding: CGFloat = 0
    static let copiedBadgeHorizontalPadding: CGFloat = 8
    static let copiedBadgeVerticalPadding: CGFloat = 6
    static let copiedBadgeIconTextSpacing: CGFloat = 4
    static let copiedBadgeShadowRadius: CGFloat = 14
    static let copiedBadgeShadowYOffset: CGFloat = 6
    static let phraseLibraryCopiedFeedbackDurationNanoseconds: UInt64 = 1_200_000_000
    static let phrasePaletteCopiedFeedbackDurationNanoseconds: UInt64 = 900_000_000
    static let toolbarControlCornerRadius: CGFloat = 10
    static let toolbarControlFontSize: CGFloat = 13
    static let toolbarControlShadowRadius: CGFloat = 20
    static let toolbarControlShadowYOffset: CGFloat = 8
    static let toolbarControlPressedOpacity: Double = 0.72

    static func copiedBadgeBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    static func accentForeground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(
                red: accentForegroundDarkRed,
                green: accentForegroundDarkGreen,
                blue: accentForegroundDarkBlue
            )
        }

        return Color(
            red: accentForegroundLightRed,
            green: accentForegroundLightGreen,
            blue: accentForegroundLightBlue
        )
    }

    static func copiedBadgeForeground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    static func copiedBadgeShadowColor(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? 0.36 : 0.28)
    }
}

enum LazyQuipsToolbarButtonTone {
    case action
    case utility

    func foreground(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .action:
            LazyQuipsVisualStyle.accentForeground(for: colorScheme)
        case .utility:
            Color.secondary
        }
    }
}

struct LazyQuipsToolbarButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    let width: CGFloat
    let height: CGFloat
    let tone: LazyQuipsToolbarButtonTone
    let usesLiquidGlass: Bool

    init(
        width: CGFloat,
        height: CGFloat,
        tone: LazyQuipsToolbarButtonTone = .action,
        usesLiquidGlass: Bool = false
    ) {
        self.width = width
        self.height = height
        self.tone = tone
        self.usesLiquidGlass = usesLiquidGlass
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: LazyQuipsVisualStyle.toolbarControlFontSize))
            .foregroundStyle(tone.foreground(for: colorScheme))
            .frame(width: width, height: height)
            .lazyQuipsToolbarControlSurface(usesLiquidGlass: usesLiquidGlass)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? LazyQuipsVisualStyle.toolbarControlPressedOpacity : 1)
    }
}

struct LazyQuipsToolbarGlassGroup<Content: View>: View {
    let spacing: CGFloat
    private let content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

private struct LazyQuipsToolbarControlSurface: ViewModifier {
    let usesLiquidGlass: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: LazyQuipsVisualStyle.toolbarControlCornerRadius,
            style: .continuous
        )

        if usesLiquidGlass {
            if #available(macOS 26.0, *) {
                content
                    .glassEffect(.regular, in: shape)
                    .overlay {
                        shape.stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(
                        color: .black.opacity(0.12),
                        radius: LazyQuipsVisualStyle.toolbarControlShadowRadius,
                        x: 0,
                        y: LazyQuipsVisualStyle.toolbarControlShadowYOffset
                    )
            } else {
                fallbackSurface(content: content, shape: shape)
            }
        } else {
            fallbackSurface(content: content, shape: shape)
        }
    }

    private func fallbackSurface(
        content: Content,
        shape: RoundedRectangle
    ) -> some View {
        content
            .background(.regularMaterial, in: shape)
            .overlay {
                shape.stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
            .shadow(
                color: .black.opacity(0.12),
                radius: LazyQuipsVisualStyle.toolbarControlShadowRadius,
                x: 0,
                y: LazyQuipsVisualStyle.toolbarControlShadowYOffset
            )
    }
}

extension View {
    func lazyQuipsToolbarControlSurface(usesLiquidGlass: Bool = false) -> some View {
        modifier(LazyQuipsToolbarControlSurface(usesLiquidGlass: usesLiquidGlass))
    }
}

struct LazyQuipsRowBoundaryOverlay: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LazyQuipsVisualStyle.rowBoundary)
                .frame(height: 0.5)

            Spacer(minLength: 0)

            Rectangle()
                .fill(LazyQuipsVisualStyle.rowBoundary)
                .frame(height: 0.5)
        }
    }
}

enum PhraseShortcutPreview {
    static let columnWidth: CGFloat = 73
    static let wrappingWidth: CGFloat = 64
    static let maximumLineCount = 2
}

struct LazyQuipsCopiedBadge: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var checkmarkProgress: CGFloat = 0

    let language: AppLanguage

    var body: some View {
        HStack(spacing: LazyQuipsVisualStyle.copiedBadgeIconTextSpacing) {
            checkmark

            Text(AppStrings.text(.copied, language: language))
                .font(.system(size: 12, weight: .semibold))
        }
        .lineLimit(1)
        .padding(.horizontal, LazyQuipsVisualStyle.copiedBadgeHorizontalPadding)
        .padding(.vertical, LazyQuipsVisualStyle.copiedBadgeVerticalPadding)
        .foregroundStyle(LazyQuipsVisualStyle.copiedBadgeForeground(for: colorScheme))
        .background(
            LazyQuipsVisualStyle.copiedBadgeBackground(for: colorScheme),
            in: RoundedRectangle(cornerRadius: 5, style: .continuous)
        )
        .shadow(
            color: LazyQuipsVisualStyle.copiedBadgeShadowColor(for: colorScheme),
            radius: LazyQuipsVisualStyle.copiedBadgeShadowRadius,
            x: 0,
            y: LazyQuipsVisualStyle.copiedBadgeShadowYOffset
        )
        .transition(transition)
        .accessibilityLabel(AppStrings.text(.copied, language: language))
        .onAppear(perform: startCheckmarkAnimation)
    }

    @ViewBuilder
    private var checkmark: some View {
        LazyQuipsCheckmarkShape()
            .trim(from: 0, to: accessibilityReduceMotion ? 1 : checkmarkProgress)
            .stroke(
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 10, height: 8)
            .accessibilityHidden(true)
    }

    private func startCheckmarkAnimation() {
        guard !accessibilityReduceMotion else {
            checkmarkProgress = 1
            return
        }

        checkmarkProgress = 0
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.22)) {
                checkmarkProgress = 1
            }
        }
    }

    private var transition: AnyTransition {
        if accessibilityReduceMotion {
            return .identity
        }

        return .asymmetric(
            insertion: .scale(scale: 0.94).combined(with: .opacity),
            removal: .opacity
        )
    }
}

private struct LazyQuipsCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.08))
        return path
    }
}
