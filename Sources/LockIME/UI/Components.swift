import LockIMEKit
import SwiftUI

/// A standard app row — icon + display name + bundle identifier — shared by the
/// App Rules pane and the app picker so both read with identical rhythm.
struct AppRowLabel: View {
    let bundleID: String
    /// Optional pre-resolved display name (e.g. from `InstalledApp`), avoiding a
    /// second workspace lookup.
    var name: String?
    /// Optional pre-resolved icon (e.g. cached by a long list), avoiding a
    /// `NSWorkspace` lookup on every row render.
    var icon: NSImage?
    var iconSize: CGFloat = DS.Size.rowIcon

    init(bundleID: String, name: String? = nil, icon: NSImage? = nil, iconSize: CGFloat = DS.Size.rowIcon) {
        self.bundleID = bundleID
        self.name = name
        self.icon = icon
        self.iconSize = iconSize
    }

    var body: some View {
        HStack(spacing: DS.Spacing.lg) {
            iconView
                .frame(width: iconSize, height: iconSize)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(name ?? AppDisplay.name(for: bundleID))
                    .font(DS.Font.rowTitle)
                Text(bundleID)
                    .font(DS.Font.rowSubtitle)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let nsImage = icon ?? AppDisplay.icon(for: bundleID) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
        } else {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(.quaternary)
                .overlay(
                    Image(systemName: "app.dashed")
                        .foregroundStyle(.secondary)
                )
        }
    }
}

/// A grouped-`Form` section footer with the standard footnote/secondary styling,
/// replacing the repeated `Text(...).font(.footnote).foregroundStyle(.secondary)`.
struct SectionFooter: View {
    private let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        Text(text)
            .font(DS.Font.sectionFooter)
            .foregroundStyle(.secondary)
    }
}
