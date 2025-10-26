import SwiftUI

public struct IconBadge: View {
    public let systemName: String
    public let color: Color

    public init(systemName: String, color: Color) {
        self.systemName = systemName
        self.color = color
    }

    public var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.18))
            Image(systemName: systemName)
                .foregroundStyle(color)
        }
        .frame(width: 34, height: 34)
    }
}
