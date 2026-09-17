# Pirnbox

Tap the glass bobbin to spend remaining thread, then reload it to capacity.

Pirnbox is for home sewists who empty a bobbin mid-seam and want remaining thread on the glass, not a stitch diary. There is no account, no catalog, and no Game tab.

## Architecture

Bobbin-spend encoding. Remaining and Capacity are separate integers. Remaining starts at Capacity and then lives on its own. A `Stitch` writes Remaining minus one and floors at zero. A stitch while Remaining is already zero writes `Bare` and leaves Remaining at zero, so a bare spool never hangs an extra unit. `Reload` writes a `ReloadMark` that stores remainingBefore and sets Remaining to Capacity. Reload while Remaining already equals Capacity is a no-op. `Retract` peels the last write: a Stitch restores one, a ReloadMark restores remainingBefore, and a Bare peels without changing Remaining.

`BobbinStore` owns the fold of Stitch, Bare, and ReloadMark keyed as Int YYYYMMDD from `Calendar.current.startOfDay`. Views call `stitch`, `reload`, and `retract`. They never touch UserDefaults.

This pattern fits the product. The home verb is stitch-the-bobbin. Remaining is the live thread column. Capacity is the spool size Reload restores. A tab plus a list of log rows would be a journal clone.

Persistence is one Codable `BobbinDocument` (schemaVersion 1) in UserDefaults under `pnb.bobbin.v1`, with an atomic file projection in Application Support. Views never touch storage.

Home never leaves. Calendar, Charts, History, and Settings arrive as sheets over the locked glass bobbin. There is no TabView.

## Stitch then reload

This is why someone picks Pirnbox. Tap the glass to spend one unit from Remaining. At zero, a tap writes Bare and Remaining stays at zero. Reload files a ReloadMark and restores Remaining to Capacity. Retract peels the last stitch or the last reload. There is no stitch-count field and no project list. Calendar counts ReloadMarks. Charts compare stitches to Capacity. Settings sets integer Capacity.

The live remaining-versus-capacity column sits on home. A dedicated screen, **Stitch then reload**, walks the same mechanic.

## Design

Rose quartz calm. Palette lives in `Assets.xcassets` and is reached only through `BobbinPaint`: background `#FBF9F4`, surface `#FEFEFD`, ink `#392F18`, accent `#CC9719`, muted `#80704D`. Type is SF Pro via `Font.system` in a six-step Dynamic Type scale (`BobbinType.Step`). Spacing unit 8 pt. Card radius 20 pt. Chip radius 12 pt. Elevation is one soft drop shadow. Primary controls are soft cards.

Home rhythm is conversation: a soft header, remaining and capacity as speech of varying width, composer full width at the bottom for Reload and Retract. Motion is quiet. Numbers tick. Reduce Motion instant-swaps.

## Art

Style: 3D glass render glassmorphism, metriccapacity take.

Base prompt reused for every asset:

```
3D glass render, frosted translucent glassmorphism, soft studio light, a home-sewing glass bobbin as a calm still life, remaining thread as a live inner column against the clear spool walls, refraction and milky frost, quiet product photography mood, isolated subjects, no readable text, no letters, no logo, no specified hues
```

| Image set | Prompt |
| --- | --- |
| `pnb_AppIcon` | Single 3D glass sewing bobbin filling the canvas edge to edge, inner thread column visible through frosted glass, glassmorphism, studio soft focus, no text, no letters, no rounded corners, no drop shadow, opaque, subject inside the middle 80 percent |
| `pnb_Splash` | Vertical 3D glass bobbin still life, frosted glassmorphism, quiet uncluttered centre band, studio soft focus, no readable text |
| `pnb_Onboarding1` | 3D glass still life of a full glass bobbin on a sewing table, the product in one glance, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_Onboarding2` | 3D glass mid-gesture: a finger tapping the glass bobbin so the inner thread column drops one unit, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_Onboarding3` | 3D glass bobbin after a reload, thread column restored to the spool walls, a small reload mark beside it, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_EmptyHome` | 3D glass empty bobbin with no thread on the spool, waiting, calm and inviting, never sad, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_EmptyList` | 3D glass empty history leaf with no stitch or reload marks, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_CardBackdrop` | Abstract frosted glass and thread-column refraction, low contrast so type can sit on top, 3D glass render, no letters, fills the canvas |
| `pnb_ControlFace` | Face of the glass bobbin as a physical control, inner thread column, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_TwistHero` | 3D glass emblem of stitch-then-reload: a spent bobbin beside a refilled spool, one bare mark, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_SuccessMark` | Small 3D glass stitch-click confirmation spark on a bobbin rim, frosted glassmorphism, isolated cutout, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `pnb_HeaderDecor` | Wide 3D glass bobbin-and-thread band, frosted spools in a quiet row, low contrast, no readable text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |

Assets are generated by the factory `assets.generate` step. This tree ships empty imagesets named as above.

## How this is not a repeat

Family stays `metric_capacity` as the uniqueness-graph seed required, but the job is not another fill-up pair in five-tab chrome. Home is a locked glass bobbin: stitch spends remaining thread, reload files a ReloadMark and restores Remaining to Capacity, and a stitch at zero writes Bare without hanging an extra unit. That is not Waywiser click-up, not Withycreel overhang keep, not Castellum water vessels, not Diapason bellows Wind, and not a loom journal with swapped nouns. Calendar, Charts, History, and Settings are sheets plus deep-link routes. No Scan, Search, or Game chrome.

## Build

```bash
cd Pirnbox
xcodegen generate
xcodebuild build-for-testing -scheme Pirnbox -destination 'generic/platform=iOS Simulator'
xcodebuild -scheme Pirnbox -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.pirnbox.bobbin`. Contact: https://pirnbox-bobbin.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Extra slugs `calendar`, `charts`, and `stitchthenreload` open those sheets. Simulator seed uses `pnb.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
