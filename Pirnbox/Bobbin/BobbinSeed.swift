import Foundation

/// Role: Bobbin. Simulator-only demo behind pnb.demo.v1. Device never seeds.
enum BobbinSeed {
    static func document(now: Date, calendar: Calendar) -> BobbinDocument {
        var document = BobbinDocument.fresh(capacity: 12)
        let plan: [(offset: Int, stitches: Int, reload: Bool)] = [
            (-4, 6, true),
            (-3, 9, true),
            (-2, 4, true),
            (-1, 7, true),
            (0, 5, false),
        ]
        for step in plan {
            let moment = calendar.date(byAdding: .day, value: step.offset, to: now) ?? now
            for _ in 0 ..< step.stitches {
                document.stitch(at: moment, calendar: calendar)
            }
            if step.reload {
                document.reload(at: moment, calendar: calendar)
            }
        }
        document.onboardingComplete = true
        return document
    }
}
