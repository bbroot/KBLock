import SwiftUI

/// LockIME's single source of truth for visual design — spacing, radii, sizes,
/// color, typography, and motion. Caseless namespaced enums (zero runtime cost,
/// no accidental init). Reference these tokens everywhere; never inline literals.
///
/// The whole app reads as one coherent, system-native design language in both
/// light and dark appearance. Values follow a 4-pt rhythm and the macOS control
/// scale (13-pt baseline, not iOS). See `docs/DESIGN.md` for the full spec.
///
/// > Inside `.formStyle(.grouped)` Forms the Form owns its insets — do **not**
/// > add spacing/padding there. These tokens apply to custom views (About,
/// > Update, App picker, confirmations).
enum DS {

    // MARK: - Spacing (4-pt grid)

    enum Spacing {
        /// 2 — icon↔caption gap, vertical micro-pad.
        static let xxs: CGFloat = 2
        /// 4 — tight inline.
        static let xs: CGFloat = 4
        /// 6 — compact stacks.
        static let sm: CGFloat = 6
        /// 8 — default control gap.
        static let md: CGFloat = 8
        /// 12 — row HStack (icon↔text).
        static let lg: CGFloat = 12
        /// 16 — window content padding inside custom panels.
        static let xl: CGFloat = 16
        /// 24 — between section groups (when not Form-managed).
        static let xxl: CGFloat = 24
        /// 32 — About-window rhythm blocks / hero padding.
        static let section: CGFloat = 32
    }

    // MARK: - Corner radius

    enum Radius {
        /// 6 — custom small controls, chips.
        static let control: CGFloat = 6
        /// 10 — grouped-form-style cards/rows.
        static let row: CGFloat = 10
        /// 12 — update/about window inner containers.
        static let panel: CGFloat = 12
        /// 16 — sheets.
        static let sheet: CGFloat = 16
    }

    // MARK: - Element sizes

    enum Size {
        /// 22 — app icon in a settings rule row.
        static let rowIcon: CGFloat = 22
        /// 32 — app icon in the picker list.
        static let pickerIcon: CGFloat = 32
        /// 52 — app icon in the update-window header.
        static let updateHeaderIcon: CGFloat = 52
        /// 128 — app icon on the About screen.
        static let aboutIcon: CGFloat = 128
        /// 280 — determinate progress bar in the update footer (wide enough for
        /// the size/speed/remaining detail line).
        static let progressBar: CGFloat = 280
    }

    // MARK: - Window & sheet sizes

    enum Window {
        static let aboutWidth: CGFloat = 340
        static let updateWidth: CGFloat = 540
        static let updateHeight: CGFloat = 480
        static let pickerWidth: CGFloat = 440
        static let pickerHeight: CGFloat = 500
        static let acknowledgementsWidth: CGFloat = 360
        static let acknowledgementsHeight: CGFloat = 320
    }

    // MARK: - Color (semantic; adapts to light/dark automatically)

    enum Palette {
        /// Brand accent (AccentColor asset — "Lock Indigo", light + dark + high
        /// contrast variants). Set as the target Global Accent Color so it also
        /// reaches AppKit Pickers/checkboxes/focus rings.
        static let accent = Color.accentColor
        /// Positive result (up to date, granted).
        static let success = Color.green
        /// Warning / attention.
        static let warning = Color.orange
        /// Destructive / error.
        static let danger = Color.red
    }

    // MARK: - Typography (semantic macOS styles — never `.system(size:)`)

    enum Font {
        /// About app name — ~22pt semibold.
        static let appName = SwiftUI.Font.title.weight(.semibold)
        /// Update-window header title — ~17pt bold.
        static let windowTitle = SwiftUI.Font.title2.bold()
        /// List-row title, settings labels — 13pt.
        static let rowTitle = SwiftUI.Font.body
        /// Version / secondary value — 12pt.
        static let version = SwiftUI.Font.callout
        /// Bundle IDs and dense metadata — 10pt.
        static let rowSubtitle = SwiftUI.Font.caption2
        /// Form section footers — 10pt.
        static let sectionFooter = SwiftUI.Font.footnote
        /// Copyright line — 10pt.
        static let copyright = SwiftUI.Font.caption
        /// Update-window phase subtitle — 11pt.
        static let subtitle = SwiftUI.Font.subheadline
        /// Release-notes version headline — ~22pt semibold.
        static let notesVersion = SwiftUI.Font.title.weight(.semibold)
        /// Colored capsule chip label — 11pt semibold.
        static let chip = SwiftUI.Font.subheadline.weight(.semibold)
        /// Size/speed/remaining detail under the download progress bar — 10pt.
        static let progressDetail = SwiftUI.Font.caption
    }

    // MARK: - Motion

    enum Motion {
        /// Lock toggle + signature symbol swap.
        static let toggle = Animation.spring(response: 0.3, dampingFraction: 0.85)
        /// Rule list insert/remove.
        static let list = Animation.smooth(duration: 0.25)
        /// Transient confirmation appear.
        static let confirmIn = Animation.easeOut(duration: 0.18)
        /// Transient confirmation dismiss.
        static let confirmOut = Animation.easeIn(duration: 0.22)
        /// How long an inline result lingers before clearing.
        static let resultDwell: Duration = .seconds(3)
    }
}
