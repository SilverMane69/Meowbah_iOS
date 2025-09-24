import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct VideoDetailsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let video: Video

    @State private var showSafari = false

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = video.thumbnailURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Color.gray.frame(height: 180)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Text(video.title)
                    .font(.title2).bold()
                    .foregroundStyle(palette.textPrimary)

                if let date = video.publishedAtFormatted, !date.isEmpty {
                    Text(date)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                HStack {
                    if let duration = video.formattedDuration, !duration.isEmpty {
                        Label(duration, systemImage: "clock")
                            .foregroundStyle(palette.textSecondary)
                    }
                    Spacer()
#if !os(tvOS)
                    if video.watchURL != nil {
                        Button {
                            showSafari = true
                        } label: {
                            Label("Watch on YouTube", systemImage: "play.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.primary)
                    }
#endif
                }
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("Video Details")
        .navigationBarTitleDisplayMode(.inline)
#if !os(tvOS)
        .sheet(isPresented: $showSafari) {
            if let url = video.watchURL {
                SafariView(url: url)
            }
        }
#endif
    }
}

#if !os(tvOS) && canImport(SafariServices)
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

#Preview {
    let sample = Video(
        id: "abc123",
        title: "Sample Video Title",
        description: "Description",
        thumbnailURL: URL(string: "https://i.ytimg.com/vi/abc123/hqdefault.jpg"),
        publishedAt: Date(),
        channelTitle: "Channel",
        durationSeconds: 245
    )
    return NavigationStack {
        VideoDetailsView(video: sample)
            .environmentObject(ThemeManager())
    }
}
