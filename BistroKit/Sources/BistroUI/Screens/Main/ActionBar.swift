import SwiftUI
import GameCore

/// tabs.bar — the action bar: h 106 + safe area, radius.sheet on top, 5 entries with their
/// label always visible. The Lab (most frequent action) is a 78 pt button overhanging by 36 pt.
/// Order from the design: Regulars · Upgrades · Lab · Menu · Shop.
struct ActionBar: View {
    let onSelect: (Destination) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            item(.regulars, icon: "people", label: "tab.regulars")
            item(.upgrades, icon: "upgrade", label: "tab.upgrades")
            labButton
            item(.menu, icon: "menu", label: "tab.menu")
            item(.shop, icon: "shop", label: "tab.shop")
        }
        .padding(.horizontal, Theme.Spacing.s2)
        .padding(.bottom, Theme.Spacing.s3)
        .frame(height: Theme.Size.actionBarHeight, alignment: .bottom)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet, topTrailingRadius: Theme.Radius.sheet)
                .fill(Theme.Colors.surfaceCard)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet, topTrailingRadius: Theme.Radius.sheet)
                        .stroke(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui)
                )
                .shadow(color: Theme.Shadow.sheetColor, radius: Theme.Shadow.sheetRadius, y: Theme.Shadow.sheetY)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func item(_ destination: Destination, icon: String, label: String) -> some View {
        Button {
            onSelect(destination)
        } label: {
            VStack(spacing: Theme.Spacing.s1) {
                GameImage(AssetName.uiIcon(icon))
                    .frame(width: Theme.Size.iconM, height: Theme.Size.iconM)
                Text(L10n.string(label))
                    .typography(Theme.Typography.labelTab)
                    .foregroundStyle(Theme.Colors.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.Layout.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var labButton: some View {
        Button {
            onSelect(.lab)
        } label: {
            VStack(spacing: Theme.Spacing.s1) {
                GameImage(AssetName.uiIcon("lab"))
                    .frame(width: Theme.Size.iconM, height: Theme.Size.iconM)
                    .frame(width: Theme.Size.labButton, height: Theme.Size.labButton)
                    .background(Circle().fill(Theme.Colors.accentGold))
                    .overlay(Circle().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.strong))
                    .inkShadow(Theme.Shadow.m, in: Circle())
                Text(L10n.string("tab.lab"))
                    .typography(Theme.Typography.labelTab)
                    .foregroundStyle(Theme.Colors.inkPrimary)
            }
            .padding(.top, -Theme.Size.labButtonOverhang)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
