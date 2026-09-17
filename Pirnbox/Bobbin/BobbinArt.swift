import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Role: Bobbin. Section 13 imagesets. Named art only when a bitmap is present.
enum BobbinArt {
    static let onboarding1 = "pnb_Onboarding1"
    static let onboarding2 = "pnb_Onboarding2"
    static let onboarding3 = "pnb_Onboarding3"
    static let emptyHome = "pnb_EmptyHome"
    static let emptyList = "pnb_EmptyList"
    static let cardBackdrop = "pnb_CardBackdrop"
    static let controlFace = "pnb_ControlFace"
    static let twistHero = "pnb_TwistHero"
    static let successMark = "pnb_SuccessMark"
    static let headerDecor = "pnb_HeaderDecor"

    static func present(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        false
        #endif
    }
}

/// Role: Bobbin. Cutout when the imageset has pixels, otherwise a quiet surface.
struct BobbinCutout: View {
    var name: String
    var maxHeight: CGFloat = BobbinSpace.step(28)

    var body: some View {
        Group {
            if BobbinArt.present(name) {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                BobbinPaint.surface
                    .clipShape(BobbinRound.cardShape)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: maxHeight)
        .accessibilityHidden(true)
    }
}

/// Role: Bobbin. Day keys as locale dates. Numbers stay on BobbinType.figure.
enum BobbinStamp {
    static func date(from dayKey: Int, calendar: Calendar = .current) -> Date {
        var parts = DateComponents()
        parts.year = dayKey / 10_000
        parts.month = (dayKey / 100) % 100
        parts.day = dayKey % 100
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    static func dayName(_ dayKey: Int, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date(from: dayKey, calendar: calendar))
    }

    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
