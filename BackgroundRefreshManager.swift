//
//  BackgroundRefreshManager.swift
//  Meowbah
//
//  Periodically fetches the YouTube RSS feed in the background and posts local notifications for new videos.
//

#if canImport(BackgroundTasks)

import Foundation
import BackgroundTasks
import UserNotifications
import SwiftUI
import Combine

enum BackgroundRefreshConfig {
    // The task identifier must also appear in Info.plist under BGTaskSchedulerPermittedIdentifiers.
    static let refreshTaskIdentifier = "com.meowbah.refresh"

    // How often we ask iOS to wake us. iOS may coalesce/schedule differently.
    static let minimumRefreshInterval: TimeInterval = 30 * 60 // 30 minutes
}

// A simple store for seen video IDs to detect new items.
private enum SeenVideosStore {
    private static let key = "SeenVideoIDs"

    static func load() -> Set<String> {
        let arr = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return Set(arr)
    }

    static func save(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

@MainActor
final class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()

    private init() { }

    // Call from app launch
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundRefreshConfig.refreshTaskIdentifier, using: nil) { task in
            // Handle background refresh task
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    // Call when entering background (or at suitable times) to schedule the next refresh
    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundRefreshConfig.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: BackgroundRefreshConfig.minimumRefreshInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
            // print("[BGTask] Scheduled next refresh")
        } catch {
            // print("[BGTask] Failed to schedule: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh immediately so we keep getting opportunities
        scheduleNextRefresh()

        // Create an operation that runs the RSS fetch and notification logic.
        let operation = BackgroundFetchOperation()

        // Expiration handler: cancel work if iOS asks us to stop.
        task.expirationHandler = {
            operation.cancel()
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        // Kick off on a background queue
        OperationQueue().addOperation(operation)
    }
}

// MARK: - BackgroundFetchOperation

private final class BackgroundFetchOperation: Operation {
    private var isOpFinished = false
    private var isOpExecuting = false

    override var isAsynchronous: Bool { true }
    override private(set) var isFinished: Bool {
        get { isOpFinished }
        set {
            willChangeValue(forKey: "isFinished")
            isOpFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    override private(set) var isExecuting: Bool {
        get { isOpExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            isOpExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    override func start() {
        if isCancelled {
            finish()
            return
        }
        isExecuting = true

        Task {
            await run()
            finish()
        }
    }

    private func finish() {
        isExecuting = false
        isFinished = true
    }

    private func run() async {
        // Ensure we have notification permission (no prompt here; app should request at least once in foreground)
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        // Fetch via official API
        let channelId = "UCNytjdD5-KZInxjVeWV_qQw" // Consider making this configurable
        let maxResults = 10

        do {
            let videos = try await YouTubeAPIClient.shared.fetchLatestVideos(channelId: channelId, maxResults: maxResults)
            guard !videos.isEmpty else { return }

            // Detect new IDs
            var seen = SeenVideosStore.load()
            let newOnes = videos.filter { !seen.contains($0.id) }

            // Schedule a notification for the newest unseen video (if any)
            if let newest = newOnes.sorted(by: { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }).first {
                await NotificationHelper.scheduleNewVideoNotification(video: newest)
            }

            // Update seen IDs with the latest snapshot (limit to some size)
            let latestIDs = Set(videos.prefix(50).map { $0.id })
            seen.formUnion(latestIDs)
            SeenVideosStore.save(seen)
        } catch {
            // Swallow network errors in background
            // print("[BGTask] Fetch failed: \(error)")
        }
    }
}

#else

// Fallback stub so the symbol exists when BackgroundTasks is unavailable (e.g., previews/tests/other targets).
import Foundation
import SwiftUI
import Combine

@MainActor
final class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()
    private init() { }

    func register() { /* no-op */ }
    func scheduleNextRefresh() { /* no-op */ }
}

#endif
