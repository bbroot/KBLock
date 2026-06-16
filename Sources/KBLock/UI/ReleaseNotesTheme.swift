import AppKit
import MarkdownUI
import SwiftUI

extension Theme {
    /// Markdown theme for the update window's release notes, on the macOS 13-pt
    /// control scale. Derived from `.gitHub` (keeps its list, code-block, and
    /// table styling) but drops the web-sized 16-pt base, the hard-coded page
    /// background, and the underlined web headings in favor of native panel
    /// typography (17/15/13 heading steps).
    @MainActor static let releaseNotes = Theme.gitHub
        .text {
            FontSize(NSFont.systemFontSize)
        }
        .heading1 { configuration in
            configuration.label
                .markdownMargin(top: .em(1.4), bottom: .em(0.6))
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.31))
                }
        }
        .heading2 { configuration in
            configuration.label
                .markdownMargin(top: .em(1.4), bottom: .em(0.6))
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.15))
                }
        }
        .heading3 { configuration in
            configuration.label
                .markdownMargin(top: .em(1.2), bottom: .em(0.5))
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1))
                }
        }
}
