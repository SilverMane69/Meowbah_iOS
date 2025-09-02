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

    private enum CodingKeys: String, CodingKey {
        case items
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try c.decode([YouTubeSearchItem].self, forKey: .items)
    }
}

struct YouTubeSearchItem: Decodable {
    struct ID: Decodable {
        let kind: String?
        let videoId: String?

        private enum CodingKeys: String, CodingKey {
            case kind
            case videoId
        }

        nonisolated init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.kind = try c.decodeIfPresent(String.self, forKey: .kind)
            self.videoId = try c.decodeIfPresent(String.self, forKey: .videoId)
        }
    }
    struct Snippet: Decodable {
        struct Thumbnails: Decodable {
            struct Thumb: Decodable {
                let url: String?
                let width: Int?
                let height: Int?

                private enum CodingKeys: String, CodingKey {
                    case url, width, height
                }

                nonisolated init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    self.url = try c.decodeIfPresent(String.self, forKey: .url)
                    self.width = try c.decodeIfPresent(Int.self, forKey: .width)
                    self.height = try c.decodeIfPresent(Int.self, forKey: .height)
                }
            }
            let `default`: Thumb?
            let medium: Thumb?
            let high: Thumb?
            let standard: Thumb?
            let maxres: Thumb?

            private enum CodingKeys: String, CodingKey {
                case `default` = "default"
                case medium, high, standard, maxres
            }

            nonisolated init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                self.default = try c.decodeIfPresent(Thumb.self, forKey: .default)
                self.medium = try c.decodeIfPresent(Thumb.self, forKey: .medium)
                self.high = try c.decodeIfPresent(Thumb.self, forKey: .high)
                self.standard = try c.decodeIfPresent(Thumb.self, forKey: .standard)
                self.maxres = try c.decodeIfPresent(Thumb.self, forKey: .maxres)
            }
        }

        let publishedAt: String?
        let channelId: String?
        let title: String?
        let description: String?
        let thumbnails: Thumbnails?
        let channelTitle: String?

        private enum CodingKeys: String, CodingKey {
            case publishedAt, channelId, title, description, thumbnails, channelTitle
        }

        nonisolated init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.publishedAt = try c.decodeIfPresent(String.self, forKey: .publishedAt)
            self.channelId = try c.decodeIfPresent(String.self, forKey: .channelId)
            self.title = try c.decodeIfPresent(String.self, forKey: .title)
            self.description = try c.decodeIfPresent(String.self, forKey: .description)
            self.thumbnails = try c.decodeIfPresent(Thumbnails.self, forKey: .thumbnails)
            self.channelTitle = try c.decodeIfPresent(String.self, forKey: .channelTitle)
        }
    }

    let id: ID
    let snippet: Snippet

    private enum CodingKeys: String, CodingKey {
        case id, snippet
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(ID.self, forKey: .id)
        self.snippet = try c.decode(Snippet.self, forKey: .snippet)
    }
}

// For durations (Videos endpoint)
struct YouTubeVideosResponse: Decodable {
    let items: [YouTubeVideoItem]

    private enum CodingKeys: String, CodingKey {
        case items
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try c.decode([YouTubeVideoItem].self, forKey: .items)
    }
}

struct YouTubeVideoItem: Decodable {
    let id: String
    let contentDetails: ContentDetails

    struct ContentDetails: Decodable {
        let duration: String // ISO8601 duration, e.g., "PT4M13S"

        private enum CodingKeys: String, CodingKey {
            case duration
        }

        nonisolated init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.duration = try c.decode(String.self, forKey: .duration)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, contentDetails
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.contentDetails = try c.decode(ContentDetails.self, forKey: .contentDetails)
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

// MARK: - Nonisolated JSON decode helper

// Perform decoding outside any actor isolation to avoid isolated-conformance mismatches.
@inline(__always)
nonisolated private func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}

// MARK: - YouTube API Client

actor YouTubeAPIClient {
    static let shared = YouTubeAPIClient()

    // NOTE: Consider restricting this key in Google Cloud Console.
    private let apiKey = "AIzaSyC2OviBSUQ4TIzR76g0doH6HX2b32LI10s"
    private let searchBase = URL(string: "https://www.googleapis.com/youtube/v3/search")!
    private let videosBase = URL(string: "https://www.googleapis.com/youtube/v3/videos")!

    func fetchLatestVideos(channelId: String, maxResults: Int = 50) async throws -> [Video] {
        // First: search to get basic info and video IDs
        var comps = URLComponents(url: searchBase, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "channelId", value: channelId),
            URLQueryItem(name: "maxResults", value: String(max(1, min(maxResults, 50)))),
            URLQueryItem(name: "order", value: "date"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "part", value: "snippet")
        ]

        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded: YouTubeSearchResponse = try decodeJSON(YouTubeSearchResponse.self, from: data)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func bestThumbURL(from thumbs: YouTubeSearchItem.Snippet.Thumbnails?) -> URL? {
            let candidates = [
                thumbs?.maxres?.url,
                thumbs?.standard?.url,
                thumbs?.high?.url,
                thumbs?.medium?.url,
                thumbs?.default?.url
            ]
            if let s = candidates.compactMap({ $0 }).first {
                return URL(string: s)
            }
            return nil
        }

        var videos: [Video] = decoded.items.compactMap { item in
            guard let vid = item.id.videoId else { return nil }
            let title = item.snippet.title ?? "Untitled"
            let desc = item.snippet.description ?? ""
            let thumb = bestThumbURL(from: item.snippet.thumbnails)
            let publishedAt: Date? = {
                guard let s = item.snippet.publishedAt else { return nil }
                return iso.date(from: s) ?? ISO8601DateFormatter().date(from: s)
            }()
            return Video(
                id: vid,
                title: title,
                description: desc,
                thumbnailURL: thumb,
                publishedAt: publishedAt,
                channelTitle: item.snippet.channelTitle,
                durationSeconds: nil
            )
        }

        // Second: fetch durations for those IDs
        if !videos.isEmpty {
            let ids = videos.map { $0.id }.joined(separator: ",")
            var vidsComps = URLComponents(url: videosBase, resolvingAgainstBaseURL: false)!
            vidsComps.queryItems = [
                URLQueryItem(name: "key", value: apiKey),
                URLQueryItem(name: "id", value: ids),
                URLQueryItem(name: "part", value: "contentDetails")
            ]

            let (vData, vResp) = try await URLSession.shared.data(from: vidsComps.url!)
            guard let vHttp = vResp as? HTTPURLResponse, (200..<300).contains(vHttp.statusCode) else {
                return videos
            }

            let vDecoded: YouTubeVideosResponse = try decodeJSON(YouTubeVideosResponse.self, from: vData)
            let durationMap: [String: Int] = Dictionary(uniqueKeysWithValues:
                vDecoded.items.compactMap { item in
                    (item.id, parseISODuration(item.contentDetails.duration))
                }
            )

            videos = videos.map { v in
                v.withDuration(durationMap[v.id])
            }
        }

        return videos
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
}
