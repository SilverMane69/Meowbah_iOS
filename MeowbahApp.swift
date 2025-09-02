//
//  MeowbahApp.swift
//  Meowbah
//
//  Created by Ryan Reid on 25/08/2025.
//

import SwiftUI

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
        // Note: UITabBar has no `compactAppearance`.

        // Make NavigationBar fully transparent across styles
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            let palette = themeManager.palette(for: colorScheme)

            ZStack {
                // App-wide themed background that always fills the window
                palette.background
                    .ignoresSafeArea()

                Group {
                    if isAuthenticated {
                        ContentView()
                    } else {
                        LoginView {
                            isAuthenticated = true
                        }
                    }
                }
                .environmentObject(themeManager)
                .tint(palette.primary)
                .animation(.default, value: isAuthenticated)
            }
        }
    }
}
