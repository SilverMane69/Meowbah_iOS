//
//  FanArtView.swift
//  Meowbah
//
//  Created by Ryan Reid on 25/08/2025.
//

import SwiftUI

struct FanArtView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<12, id: \.self) { index in
                        let isEven = index.isMultiple(of: 2)
                        let colors: [Color] = isEven
                            ? [palette.secondary, palette.primary]
                            : [palette.primary, palette.secondary]

                        FanArtTile(title: "Fan Art #\(index + 1)", colors: colors)
                    }
                }
                .padding(16)
            }
            .background(
                ZStack {
                    palette.background.ignoresSafeArea()
                }
            )
            .navigationTitle("Fan Art")
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                // Removed leading debug/status chip
            }
        }
        .tint(theme.palette(for: colorScheme).primary)
    }
}

private struct FanArtTile: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let colors: [Color]

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        let gradient = LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(gradient)
                .frame(height: 160)

            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.white)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.white)
            }
            .padding()
        }
        .shadow(color: palette.shadow.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FanArtView()
        .environmentObject(ThemeManager())
}
