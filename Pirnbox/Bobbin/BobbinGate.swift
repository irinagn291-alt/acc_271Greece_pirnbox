import SwiftUI

/// Role: Bobbin. Primary ButtonStyle. Default, pressed, disabled, loading. Stitch wears accent.
struct BobbinAccentStyle: ButtonStyle {
    var loading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        BobbinAccentBody(configuration: configuration, loading: loading)
    }
}

private struct BobbinAccentBody: View {
    var configuration: ButtonStyle.Configuration
    var loading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            configuration.label
                .opacity(loading ? 0 : 1)
            if loading {
                ProgressView()
                    .tint(BobbinPaint.ink)
            }
        }
        .font(BobbinType.font(.body))
        .foregroundStyle(BobbinPaint.ink)
        .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
        .padding(.horizontal, BobbinSpace.step(2))
        .background(isEnabled ? BobbinPaint.accent : BobbinPaint.muted)
        .clipShape(BobbinRound.cardShape)
        .contentShape(BobbinRound.cardShape)
        .scaleEffect(scale)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(BobbinSpace.motion(reduce: reduceMotion), value: configuration.isPressed)
        .animation(BobbinSpace.motion(reduce: reduceMotion), value: loading)
    }

    private var scale: CGFloat {
        if reduceMotion || loading || !isEnabled { return 1 }
        return configuration.isPressed ? BobbinSpace.pressScale : 1
    }
}

/// Role: Bobbin. Quiet composer control. Reload uses this. Not destructive, not accent.
struct BobbinQuietStyle: ButtonStyle {
    var loading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        BobbinQuietBody(configuration: configuration, loading: loading)
    }
}

private struct BobbinQuietBody: View {
    var configuration: ButtonStyle.Configuration
    var loading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            configuration.label
                .opacity(loading ? 0 : 1)
            if loading {
                ProgressView()
                    .tint(BobbinPaint.ink)
            }
        }
        .font(BobbinType.font(.body))
        .foregroundStyle(isEnabled ? BobbinPaint.ink : BobbinPaint.muted)
        .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
        .padding(.horizontal, BobbinSpace.step(2))
        .background(BobbinPaint.surface)
        .clipShape(BobbinRound.cardShape)
        .bobbinLift()
        .contentShape(BobbinRound.cardShape)
        .scaleEffect(scale)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(BobbinSpace.motion(reduce: reduceMotion), value: configuration.isPressed)
    }

    private var scale: CGFloat {
        if reduceMotion || loading || !isEnabled { return 1 }
        return configuration.isPressed ? BobbinSpace.pressScale : 1
    }
}

/// Role: Bobbin. Retract does not wear accent. Pressed opacity only.
struct BobbinRetractStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BobbinRetractBody(configuration: configuration)
    }
}

private struct BobbinRetractBody: View {
    var configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .font(BobbinType.font(.body))
            .foregroundStyle(isEnabled ? BobbinPaint.ink : BobbinPaint.muted)
            .frame(minWidth: BobbinSpace.tap, minHeight: BobbinSpace.tap)
            .padding(.horizontal, BobbinSpace.step(2))
            .background(BobbinPaint.surface)
            .clipShape(BobbinRound.chipShape)
            .contentShape(BobbinRound.chipShape)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? BobbinSpace.pressScale : 1))
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.4)
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: configuration.isPressed)
    }
}

/// Role: Bobbin. Pressed scale for the glass stitch control. Accent lives in the spool fill.
struct BobbinSpoolStyle: ButtonStyle {
    var loading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        BobbinSpoolBody(configuration: configuration, loading: loading)
    }
}

private struct BobbinSpoolBody: View {
    var configuration: ButtonStyle.Configuration
    var loading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(scale)
            .opacity(isEnabled ? 1 : 0.7)
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: configuration.isPressed)
            .overlay {
                if loading {
                    ProgressView()
                        .tint(BobbinPaint.ink)
                }
            }
    }

    private var scale: CGFloat {
        if reduceMotion || loading || !isEnabled { return 1 }
        return configuration.isPressed ? BobbinSpace.pressScale : 1
    }
}

/// Role: Bobbin. Reset and erase. Not accent. Not a red primary.
struct BobbinDestroyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BobbinDestroyBody(configuration: configuration)
    }
}

private struct BobbinDestroyBody: View {
    var configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .font(BobbinType.font(.body))
            .foregroundStyle(isEnabled ? BobbinPaint.ink : BobbinPaint.muted)
            .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap)
            .padding(.horizontal, BobbinSpace.step(2))
            .background(BobbinPaint.surface)
            .clipShape(BobbinRound.cardShape)
            .contentShape(BobbinRound.cardShape)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? BobbinSpace.pressScale : 1))
            .opacity(isEnabled ? 1 : 0.45)
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: configuration.isPressed)
    }
}

/// Role: Bobbin. Pressed scale for readouts that already own their fill. No second radius.
struct BobbinPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BobbinPressBody(configuration: configuration)
    }
}

private struct BobbinPressBody: View {
    var configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(scale)
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
            .animation(BobbinSpace.motion(reduce: reduceMotion), value: configuration.isPressed)
    }

    private var scale: CGFloat {
        if reduceMotion || !isEnabled { return 1 }
        return configuration.isPressed ? BobbinSpace.pressScale : 1
    }
}
