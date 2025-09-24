import SwiftUI

struct ArtView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: String = "All"
    @State private var artworks: [String] = [
        "Cat Sketch #1",
        "Watercolor Kawaii",
        "Pixel Meow",
        "Chibi Portrait",
        "Sticker Pack Preview",
        "Neon Cat Poster"
    ]

    private var filteredArtworks: [String] {
        if selectedCategory == "All" { return artworks }
        // Placeholder filter; replace with real model later
        return artworks.filter { _ in true }
    }

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(palette: palette)
                categoryChips(palette: palette)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredArtworks, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(palette.card)
                                .overlay(
                                    ZStack {
                                        LinearGradient(colors: [palette.primary.opacity(0.25), palette.card.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        Image(systemName: "paintpalette.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(palette.textSecondary)
                                    }
                                )
                                .frame(height: 120)

                            Text(item)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(2)
                        }
                        .padding(8)
                        .background(palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(radius: 4, y: 2)
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("Art")
    }

    @ViewBuilder
    private func header(palette: ThemePalette) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(palette.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Discover Art")
                    .font(.title2).bold()
                    .foregroundStyle(palette.textPrimary)
                Text("Curated kawaii illustrations and concepts")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func categoryChips(palette: ThemePalette) -> some View {
        let categories = ["All", "Sketches", "Color", "Pixel", "Stickers"]
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { selectedCategory = cat }) {
                        Text(cat)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? palette.primary.opacity(0.2) : palette.card)
                            .foregroundStyle(selectedCategory == cat ? palette.primary : palette.textPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        ArtView()
            .environmentObject(ThemeManager())
    }
}
