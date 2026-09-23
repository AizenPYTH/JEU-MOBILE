import SwiftUI

/// Rounded surface grouping related content, with an optional title.
public struct Card<Content: View>: View {
    private let title: String?
    private let content: Content

    public init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if let title {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            content
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .themeShadow(Theme.Shadow.card)
    }
}

#Preview {
    Card("Kitchen") {
        Text(verbatim: "Content")
    }
    .padding()
    .background(Theme.Colors.background)
}
