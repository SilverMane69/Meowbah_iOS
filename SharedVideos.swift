//
//  SharedVideos.swift
//  Meowbah
//
//  Shared models and API client for videos usable by the app and the widget.
//

import Foundation

// MARK: - YouTube API Models

struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Decodable {
    struct ID: Decodable {
        let kind: String?
        let videoId: String?
    }
    struct Snippet: Decodable {
        struct Thumbnails: Decodable {
            struct Thumb: Decodable {
                let url: String?
                let width: Int?
                let height: Int?
            }
            let `default`: Thumb?
            let medium: Thumb?
            let high: Thumb?
            let standard: Thumb?
            let maxres: Thumb?
        }

        let publishedAt: String?
        let channelId: String?
        let title: String?
        let description: String?
        let thumbnails: Thumbnails?
        let channelTitle: String?
    }

    let id: ID
    let snippet: Snippet
}

// For durations (Videos endpoint)
struct YouTubeVideosResponse: Decodable {
    let items: [YouTubeVideoItem]
}

struct YouTubeVideoItem: Decodable {
    let id: String
    let contentDetails: ContentDetails

    struct ContentDetails: Decodable {
        let duration: String // ISO8601 duration, e.g., "PT4M13S"
    }
}

// MARK: - UI Video Model

public struct Video: Identifiable, Equatable, Hashable, Sendable, Codable {
    public let id: String            // videoId
    public let title: String
    public let description: String
    public let thumbnailURL: URL?
    public let publishedAt: Date?
    public let channelTitle: String?
    public let durationSeconds: Int?

    public nonisolated init(
        id: String,
        title: String,
        description: String,
        thumbnailURL: URL?,
        publishedAt: Date?,
        channelTitle: String?,
        durationSeconds: Int?
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.publishedAt = publishedAt
        self.channelTitle = channelTitle
        self.durationSeconds = durationSeconds
    }

    public var publishedAtFormatted: String {
        guard let publishedAt else { return "" }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: publishedAt)
    }

    public var formattedDuration: String {
        guard let s = durationSeconds else { return "" }
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let seconds = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    public var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(id)")
    }

    public nonisolated func withDuration(_ seconds: Int?) -> Video {
        Video(
            id: id,
            title: title,
            description: description,
            thumbnailURL: thumbnailURL,
            publishedAt: publishedAt,
            channelTitle: channelTitle,
            durationSeconds: seconds
        )
    }
}

// MARK: - Image session (shared)

enum ImageLoaderConfig {
    static let cache: URLCache = {
        URLCache(memoryCapacity: 20 * 1024 * 1024,
                 diskCapacity: 100 * 1024 * 1024,
                 diskPath: "YouTubeImageCache")
    }()

    static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        cfg.urlCache = cache
        #if targetEnvironment(macCatalyst)
        cfg.timeoutIntervalForRequest = 12
        cfg.timeoutIntervalForResource = 20
        #else
        cfg.timeoutIntervalForRequest = 8
        cfg.timeoutIntervalForResource = 12
        #endif
        cfg.httpMaximumConnectionsPerHost = 8
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

    static func request(for url: URL) -> URLRequest {
        #if targetEnvironment(macCatalyst)
        var req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12)
        #else
        var req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8)
        #endif
        req.setValue("image/*", forHTTPHeaderField: "Accept")
        return req
    }
}

// MARK: - YouTube API Client (API-only; improved error userInfo)

actor YouTubeAPIClient {
    static let shared = YouTubeAPIClient()

    // API key is read from Info.plist (key: "YouTubeAPIKey")
    private let apiKey: String?
    private let searchBase = URL(string: "https://www.googleapis.com/youtube/v3/search")!
    private let videosBase = URL(string: "https://www.googleapis.com/youtube/v3/videos")!

    private let session: URLSession

    private let cacheURL: URL
    private let cacheFreshnessSeconds: TimeInterval = 30 * 60 // 30 minutes

    init() {
        if let key = Bundle.main.object(forInfoDictionaryKey: "YouTubeAPIKey") as? String,
           !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.apiKey = key
        } else {
            self.apiKey = nil
            print("[YouTubeAPI] Missing API key in Info.plist (YouTubeAPIKey).")
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.requestCachePolicy = .useProtocolCachePolicy
        config.httpMaximumConnectionsPerHost = 6
        #if targetEnvironment(macCatalyst)
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 40
        #else
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        #endif

        let cache = URLCache(memoryCapacity: 10 * 1024 * 1024,
                             diskCapacity: 50 * 1024 * 1024,
                             diskPath: "YouTubeAPICache")
        config.urlCache = cache

        self.session = URLSession(configuration: config)

        let baseCaches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = baseCaches.appendingPathComponent("YouTube", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.cacheURL = dir.appendingPathComponent("videos.json")
    }

    func loadCachedVideos() async -> [Video]? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < cacheFreshnessSeconds,
              let data = try? Data(contentsOf: cacheURL),
              let videos = try? JSONDecoder().decode([Video].self, from: data) else {
            return nil
        }
        print("[YouTubeAPI] Loaded cached videos: \(videos.count)")
        return videos
    }

    func saveCachedVideos(_ videos: [Video]) async {
        do {
            let data = try JSONEncoder().encode(videos)
            try data.write(to: cacheURL, options: .atomic)
            print("[YouTubeAPI] Saved videos to cache: \(videos.count)")
        } catch {
            print("[YouTubeAPI] Cache save failed: \(error.localizedDescription)")
        }
    }

    func fetchLatestVideos(channelId: String, maxResults: Int = 25) async throws -> [Video] {
        try await fetchLatestVideosViaAPI(channelId: channelId, maxResults: maxResults)
    }

    // MARK: - API path

    func fetchLatestVideosViaAPI(channelId: String, maxResults: Int = 25) async throws -> [Video] {
        guard let apiKey, !apiKey.isEmpty else {
            throw NSError(domain: "YouTubeAPI", code: -1000, userInfo: [
                NSLocalizedDescriptionKey: "Missing YouTube API key. Add YouTubeAPIKey to Info.plist."
            ])
        }

        // 1) Search endpoint to get recent video IDs + snippet
        var comps = URLComponents(url: searchBase, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "channelId", value: channelId),
            URLQueryItem(name: "order", value: "date"),
            URLQueryItem(name: "maxResults", value: String(max(1, min(maxResults, 50)))),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let searchURL = comps.url else { throw URLError(.badURL) }

        var searchReq = URLRequest(url: searchURL)
        #if targetEnvironment(macCatalyst)
        searchReq.timeoutInterval = 20
        #else
        searchReq.timeoutInterval = 15
        #endif
        searchReq.setValue("application/json", forHTTPHeaderField: "Accept")

        let (searchData, searchResp) = try await dataWithRetries(for: searchReq, retries: 2)
        try Self.throwOnNon2xx(searchResp, data: searchData, context: "Search")

        let search = try JSONDecoder().decode(YouTubeSearchResponse.self, from: searchData)
        let items = search.items
            .filter { ($0.id.kind ?? "").contains("video") && ($0.id.videoId ?? "").isEmpty == false }

        let ids = items.compactMap { $0.id.videoId }
        if ids.isEmpty { return [] }

        // 2) Videos endpoint to get durations
        var comps2 = URLComponents(url: videosBase, resolvingAgainstBaseURL: false)!
        comps2.queryItems = [
            URLQueryItem(name: "part", value: "contentDetails"),
            URLQueryItem(name: "id", value: ids.joined(separator: ",")),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let videosURL = comps2.url else { throw URLError(.badURL) }

        var videosReq = URLRequest(url: videosURL)
        #if targetEnvironment(macCatalyst)
        videosReq.timeoutInterval = 20
        #else
        videosReq.timeoutInterval = 15
        #endif
        videosReq.setValue("application/json", forHTTPHeaderField: "Accept")

        let (videosData, videosResp) = try await dataWithRetries(for: videosReq, retries: 2)
        try Self.throwOnNon2xx(videosResp, data: videosData, context: "Videos")

        let details = try JSONDecoder().decode(YouTubeVideosResponse.self, from: videosData)
        let durationsByID = Dictionary(uniqueKeysWithValues: details.items.map { ($0.id, parseISODuration($0.contentDetails.duration)) })

        // 3) Map into UI Video model
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s = s else { return nil }
            return iso.date(from: s) ?? iso2.date(from: s)
        }

        let videos: [Video] = items.compactMap { item in
            guard let vid = item.id.videoId else { return nil }
            let snip = item.snippet
            let title = snip.title ?? ""
            let desc = snip.description ?? ""
            let thumbURLString = snip.thumbnails?.maxres?.url
                ?? snip.thumbnails?.high?.url
                ?? snip.thumbnails?.medium?.url
                ?? snip.thumbnails?.default?.url
            let thumb = thumbURLString.flatMap(URL.init(string:))
            let published = parseDate(snip.publishedAt)
            let channelTitle = snip.channelTitle
            let duration = durationsByID[vid]

            return Video(
                id: vid,
                title: title,
                description: desc,
                thumbnailURL: thumb,
                publishedAt: published,
                channelTitle: channelTitle,
                durationSeconds: duration
            )
        }

        let sorted = videos.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
        await saveCachedVideos(sorted)
        return sorted
    }

    // MARK: - Lightweight retry helper

    private func dataWithRetries(for request: URLRequest, retries: Int = 2) async throws -> (Data, URLResponse) {
        var attempt = 0
        var lastError: Error?

        while attempt <= retries {
            do {
                return try await session.data(for: request)
            } catch {
                lastError = error
                if !shouldRetry(error: error) {
                    print("[YouTubeAPI] Request failed (no retry): \(error)")
                    throw error
                }
                let delay = pow(2.0, Double(attempt)) * 0.5
                print("[YouTubeAPI] Retry attempt \(attempt + 1) after \(String(format: "%.1f", delay))s due to: \(error)")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    private func shouldRetry(error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }

    // Parse ISO8601 duration like "PT1H2M3S" to seconds
    private func parseISODuration(_ s: String) -> Int {
        var hours = 0, minutes = 0, seconds = 0
        var number = ""
        for ch in s {
            if ch.isNumber {
                number.append(ch)
            } else {
                switch ch {
                case "H":
                    hours = Int(number) ?? 0; number = ""
                case "M":
                    minutes = Int(number) ?? 0; number = ""
                case "S":
                    seconds = Int(number) ?? 0; number = ""
                default:
                    break
                }
            }
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    // MARK: - Error helpers

    private static func throwOnNon2xx(_ response: URLResponse, data: Data, context: String) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            // Try to extract Google API error message and reason
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = obj["error"] as? [String: Any] {
                let code = (errorDict["code"] as? Int) ?? http.statusCode
                var message = errorDict["message"] as? String
                var extractedReason: String?
                if message == nil,
                   let errors = errorDict["errors"] as? [[String: Any]],
                   let first = errors.first {
                    message = first["message"] as? String ?? message
                    extractedReason = first["reason"] as? String
                }
                if extractedReason == nil {
                    extractedReason = errorDict["status"] as? String
                }
                let composed = [context, message, extractedReason].compactMap { $0 }.joined(separator: " – ")
                var userInfo: [String: Any] = [NSLocalizedDescriptionKey: composed]
                if let extractedReason { userInfo["reason"] = extractedReason }
                if let status = errorDict["status"] as? String { userInfo["status"] = status }
                throw NSError(domain: "YouTubeAPI", code: code, userInfo: userInfo)
            }
            throw NSError(domain: NSURLErrorDomain, code: -1011, userInfo: [NSLocalizedDescriptionKey: "\(context) HTTP \(http.statusCode)"])
        }
    }
}

/*
 // MARK: - RSS Parser (commented out)
 // Entire RSS implementation intentionally disabled.
*/
