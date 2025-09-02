//
//  MeowbahApp.swift
//  Meowbah
//
//  Created by Ryan Reid on 25/08/2025.
//

import SwiftUI
import UserNotifications
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

@main
struct MeowbahApp: App {
    @StateObject private var themeManager = ThemeManager()
    @State private var isAuthenticated = false
    @Environment(\.colorScheme) private var colorScheme

    init() {
        // Make TabBar fully transparent across styles (iPhone/iPad, standard/scrollEdge)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = .clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Make NavigationBar fully transparent across styles
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        // Register BGTask identifiers (only where BackgroundTasks is available)
        #if canImport(BackgroundTasks)
        BackgroundRefreshManager.shared.register()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            let palette = themeManager.palette(for: colorScheme)

            ZStack {
                palette.background.ignoresSafeArea()

                Group {
                    if isAuthenticated {
                        ContentView()
                    } else {
                        LoginView(
                            onLogin: { _, _ in
                                await MainActor.run { isAuthenticated = true }
                            },
                            onGuest: {
                                isAuthenticated = true
                            }
                        )
                    }
                }
                .environmentObject(themeManager)
                .tint(palette.primary)
                .animation(.default, value: isAuthenticated)
                .task {
                    #if canImport(UserNotifications)
                    // Ask for notification permission once (optional: you can also do this on first run/after login)
                    await NotificationHelper.requestAuthorizationIfNeeded()
                    #endif
                }
            }
            #if canImport(UIKit)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                // Schedule background refresh when app goes to background
                #if canImport(BackgroundTasks)
                BackgroundRefreshManager.shared.scheduleNextRefresh()
                #endif
            }
            #endif
        }
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 1280, height: 800)
        #endif
    }
}
