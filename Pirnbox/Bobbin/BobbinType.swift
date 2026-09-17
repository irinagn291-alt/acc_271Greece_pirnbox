import SwiftUI

/// Role: Bobbin. SF Pro via Font.system. Six steps, one larger title, no condensed display.
enum BobbinType {
    enum Step: CaseIterable {
        case display
        case title
        case body
        case figure
        case caption
        case quiet

        var font: Font {
            switch self {
            case .display:
                .system(.title, design: .default).weight(.semibold)
            case .title:
                .system(.title2, design: .default).weight(.semibold)
            case .body:
                .system(.body, design: .default)
            case .figure:
                .system(.body, design: .default).weight(.semibold).monospacedDigit()
            case .caption:
                .system(.caption, design: .default)
            case .quiet:
                .system(.footnote, design: .default)
            }
        }
    }

    static func font(_ step: Step) -> Font {
        step.font
    }

    static func figure(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
