import SwiftUI
import GameCore

/// Empty state for destinations whose milestone is not built yet. Follows the design's
/// empty-state pattern: illustration, one clear sentence, one way back.
struct ComingSoonScreen: View {
    let title: String
    let message: String
    let asset: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.s6) {
            SheetHeader(title, onClose: onClose)
            Spacer()
            GameImage(asset)
                .frame(width: Theme.Size.emptyStateArt, height: Theme.Size.emptyStateArt)
            Text(message)
                .typography(Theme.Typography.bodyL)
                .foregroundStyle(Theme.Colors.inkPrimary)
                .multilineTextAlignment(.center)
            Spacer()
            BistroButton(L10n.string("common.back"), action: onClose)
        }
        .padding(Theme.Layout.defaultMargin)
    }
}
