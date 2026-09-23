import SwiftUI

/// Card surface grouping related content: surface.card · radius.l · border.ui · shadow.s.
public struct Panel<Content: View>: View {
    private let title: String?
    private let content: Content

    public init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.l)
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            if let title {
                Text(title)
                    .typography(Theme.Typography.titleS)
                    .foregroundStyle(Theme.Colors.inkPrimary)
            }
            content
        }
        .padding(Theme.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Theme.Colors.surfaceCard))
        .overlay(shape.strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
        .inkShadow(Theme.Shadow.s, in: shape)
    }
}

/// Title row of a sheet: type.title.l + close button (44 pt target).
public struct SheetHeader: View {
    private let title: String
    private let onClose: () -> Void

    public init(_ title: String, onClose: @escaping () -> Void) {
        self.title = title
        self.onClose = onClose
    }

    public var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .typography(Theme.Typography.titleL)
                .foregroundStyle(Theme.Colors.inkPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: onClose) {
                GameImage(AssetName.uiIcon("close"))
                    .frame(width: Theme.Size.iconS, height: Theme.Size.iconS)
                    .frame(width: Theme.Layout.hit, height: Theme.Layout.hit)
                    .background(Circle().fill(Theme.Colors.surfaceCard))
                    .overlay(Circle().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.string("common.close")))
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.s5) {
        SheetHeader("Menu du jour") {}
        Panel("Cuisine") {
            Text(verbatim: "Contenu").typography(Theme.Typography.bodyM)
        }
    }
    .padding(Theme.Layout.defaultMargin)
    .background(Theme.Colors.bgPaper)
}
