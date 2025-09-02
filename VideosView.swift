//
//  VideosView.swift
//  Meowbah
//
//  Created by Ryan Reid on 25/08/2025.
//

import SwiftUI
import UserNotifications
import SafariServices

// MARK: - Local Notifications

private enum NotificationManager {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            // Ignore; user may deny
        }
    }

    static func scheduleNewVideoNotification(video: Video) async {
        await requestAuthorizationIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = "Nyaa~ New video just dropped!"
        content.body = video.title.isEmpty ? "Tap to watch meow!" : "“\(video.title)” is ready to watch. Tap to play!"
        content.sound = .default
        content.badge = NSNumber(value: 1)

        // Attach thumbnail if possible
        if let url = video.thumbnailURL {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("thumb-\(video.id).jpg")
                try? FileManager.default.removeItem(at: tmpURL)
                try data.write(to: tmpURL)
                let attachment = try UNNotificationAttachment(identifier: "thumb", url: tmpURL, options: nil)
                content.attachments = [attachment]
            } catch {
                // If we fail to attach, still send the notification
            }
        }

        let request = UNNotificationRequest(
            identifier: "new-video-\(video.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // ignore
        }
    }
}

// MARK: - View

struct VideosView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText: String = ""
    @State private var isRefreshing = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var videos: [Video] = []

    // Track previously seen IDs to detect new items
    @State private var knownVideoIDs: Set<String> = []

    // Sorting / Filtering
    private enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case date = "Date"
        case duration = "Duration"
        var id: String { rawValue }
    }
    @State private var selectedSort: SortOption = .date
    @State private var durationAscending: Bool = true // shortest first by default

    private let channelId = "UCNytjdD5-KZInxjVeWV_qQw"

    private var filteredVideos: [Video] {
        // Text filtering first
        let base: [Video]
        if searchText.isEmpty {
            base = videos
        } else {
            base = videos.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sort
        switch selectedSort {
        case .name:
            return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .date:
            return base.sorted { (lhs, rhs) in
                let l = lhs.publishedAt ?? .distantPast
                let r = rhs.publishedAt ?? .distantPast
                return l > r
            }
        case .duration:
            return base.sorted { lhs, rhs in
                let l = lhs.durationSeconds ?? Int.max
                let r = rhs.durationSeconds ?? Int.max
                return durationAscending ? (l < r) : (l > r)
            }
        }
    }

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        NavigationStack {
            Group {
                if isLoading && videos.isEmpty {
                    ProgressView("Loading videos…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, videos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(palette.primary)
                        Text("Failed to load videos")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                        Text(errorMessage)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.textSecondary)
                        Button {
                            runBackgroundLoad(force: false)
                        } label: {
                            Text("Retry")
                                .bold()
                        }
                        .tint(palette.primary)
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredVideos) { video in
                            NavigationLink(value: video) {
                                VideoRow(video: video)
                            }
                            .listRowBackground(Color.clear)
                            .background(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowSeparator(.hidden)
                    .navigationDestination(for: Video.self) { video in
                        VideoDetailView(video: video)
                    }
                }
            }
            .background(
                ZStack {
                    palette.background.ignoresSafeArea()
                    if colorScheme == .dark {
                        LinearGradient(
                            colors: [Color.black.opacity(0.06), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                }
            )
            .scrollIndicators(.hidden)
            .navigationTitle("Videos")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search cute videos"
            )
            .toolbar {
                // Leading: Filter menu button
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $selectedSort) {
                            Label("Sort by Name", systemImage: "textformat").tag(SortOption.name)
                            Label("Sort by Date", systemImage: "calendar").tag(SortOption.date)
                            Label("Sort by Duration", systemImage: "clock").tag(SortOption.duration)
                        }
                        .pickerStyle(.inline)

                        if selectedSort == .duration {
                            Toggle(isOn: $durationAscending) {
                                Label("Shortest first", systemImage: durationAscending ? "arrow.up" : "arrow.down")
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter videos")
                }

                // Trailing: keep refresh button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        runBackgroundLoad(force: true)
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundStyle(palette.primary)
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable {
                isRefreshing = true
                await loadVideos(force: true)
                isRefreshing = false
            }
            .task {
                if videos.isEmpty {
                    runBackgroundLoad(force: false)
                }
            }
        }
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(palette.primary)
    }

    // MARK: - Background loading helpers

    private func runBackgroundLoad(force: Bool) {
        Task.detached(priority: .background) {
            await loadVideos(force: force)
        }
    }

    // MARK: - Actions

    private func loadVideos(force: Bool = false) async {
        if isCurrentlyLoadingAndNotForced(force: force) { return }

        await MainActor.run {
            errorMessage = nil
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            let fetched = try await YouTubeAPIClient.shared.fetchLatestVideos(channelId: channelId, maxResults: 50)

            // Detect new videos compared to knownVideoIDs
            let newIDs = Set(fetched.map { $0.id }).subtracting(knownVideoIDs)
            if let newest = fetched.first(where: { newIDs.contains($0.id) }) {
                await NotificationManager.scheduleNewVideoNotification(video: newest)
            }

            await MainActor.run {
                self.videos = fetched
                self.knownVideoIDs = Set(fetched.map { $0.id })
            }
        } catch {
            await MainActor.run {
                self.errorMessage = (error as NSError).localizedDescription
            }
        }
    }

    @MainActor
    private func isCurrentlyLoadingAndNotForced(force: Bool) -> Bool {
        if isLoading && !force { return true }
        return false
    }
}

struct VideoRow: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    let video: Video

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        HStack(spacing: 12) {
            thumbnail(palette: palette)
            texts(palette: palette)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(Color.clear)
    }

    private func thumbnail(palette: ThemePalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [palette.primary, palette.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 56)

            if let url = video.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "play.rectangle.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(14)
                            .foregroundStyle(.white.opacity(0.9))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 96, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "play.rectangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 56)
                    .foregroundStyle(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Image(systemName: "play.fill")
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
        .accessibilityHidden(true)
        .background(Color.clear)
    }

    private func texts(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                if !video.formattedDuration.isEmpty {
                    Text(video.formattedDuration)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(palette.card.opacity(0.8))
                        )
                        .foregroundStyle(palette.textPrimary)
                }
            }
            if !video.publishedAtFormatted.isEmpty {
                Text(video.publishedAtFormatted)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            if !video.description.isEmpty {
                Text(video.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Detail View

private struct VideoDetailView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let video: Video
    @State private var showSafari = false

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [palette.primary, palette.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)

                    if let url = video.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "play.rectangle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(24)
                                    .foregroundStyle(.white.opacity(0.9))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Image(systemName: "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }

                // Title
                Text(video.title)
                    .font(.title2).bold()
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.leading)

                // Date
                if !video.publishedAtFormatted.isEmpty {
                    Text("Posted \(video.publishedAtFormatted)")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                // Description
                if !video.description.isEmpty {
                    Text(video.description)
                        .font(.body)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                // Play Button -> Full-screen Safari
                if let url = video.watchURL {
                    Button {
                        showSafari = true
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Play on YouTube")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [palette.primary, palette.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                    .fullScreenCover(isPresented: $showSafari) {
                        SafariView(url: url)
                            .ignoresSafeArea()
                    }
                }
            }
            .padding(16)
        }
        .background(
            ZStack {
                palette.background.ignoresSafeArea()
            }
        )
        .navigationTitle("Video")
    }
}

// MARK: - Safari wrapper

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredBarTintColor = UIColor.clear
        vc.preferredControlTintColor = UIColor.label
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No dynamic updates needed
    }
}

#Preview {
    VideosView()
        .environmentObject(ThemeManager())
}
