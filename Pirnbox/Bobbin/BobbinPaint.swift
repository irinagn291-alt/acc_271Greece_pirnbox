import SwiftUI

/// Role: Bobbin. Named colours in Assets.xcassets. Views use these tokens, never a raw hex.
enum BobbinPaint {
    static var background: Color { Color("pnb_background") }
    static var surface: Color { Color("pnb_surface") }
    static var ink: Color { Color("pnb_ink") }
    static var accent: Color { Color("pnb_accent") }
    static var muted: Color { Color("pnb_muted") }
}
