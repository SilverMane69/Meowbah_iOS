//
//  ProfileView.swift
//  Meowbah
//
//  Created by Ryan Reid on 25/08/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var username: String = "Meow Friend"
    @State private var bio: String = "I love cute videos, pastel colors, and cozy vibes."
    @State private var notificationsEnabled: Bool = true
    @AppStorage("loginSoundEnabled") private var loginSoundEnabled: Bool = true

    private let audioName = "梶浦 由記 - Sis puella magica!"
    private let audioExt = "m4a"

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let isWide = width >= 700
                    let maxFormWidth: CGFloat = 640

                    HStack {
                        if isWide { Spacer(minLength: 0) }
                        Form {
                            headerSection(palette: palette)
                            profileSection(palette: palette)
                            preferencesSection(palette: palette)
                            logoutSection(palette: palette)
                        }
                        .scrollContentBackground(.hidden)
                        .listSectionSpacing(.compact)
                        .frame(maxWidth: isWide ? maxFormWidth : .infinity, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: isWide ? 16 : 0, style: .continuous))
                        .padding(.horizontal, isWide ? 24 : 0)
                        if isWide { Spacer(minLength: 0) }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // Set nav bar/title to light (white) while keeping content unchanged
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(palette.primary)
        }
        .tint(palette.primary)
        .onChange(of: loginSoundEnabled) { enabled in
            if enabled {
                // If player was never created (app launched with toggle OFF), start it now.
                AudioPlayback.shared.ensureStartedLoop(named: audioName, ext: audioExt, respectSilent: true)
                // Ensure it’s playing (resume if it was paused).
                AudioPlayback.shared.resume()
            } else {
                AudioPlayback.shared.pause()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func headerSection(palette: ThemePalette) -> some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [palette.primary, palette.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: "cat.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(username)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Member since 2025")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
            }
        }
        .listRowBackground(palette.card)
    }

    @ViewBuilder
    private func profileSection(palette: ThemePalette) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.footnote).bold()
                    .foregroundStyle(palette.textSecondary)
                TextField("Username", text: $username)
                    .foregroundStyle(palette.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.footnote).bold()
                    .foregroundStyle(palette.textSecondary)
                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(2...4)
                    .foregroundStyle(palette.textPrimary)
            }
        } header: {
            Text("Profile")
                .foregroundStyle(palette.textSecondary)
        }
        .listRowBackground(palette.card)
    }

    @ViewBuilder
    private func preferencesSection(palette: ThemePalette) -> some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label {
                    Text("Notifications")
                        .foregroundStyle(palette.textPrimary)
                } icon: {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(palette.primary)
                }
            }

            Toggle(isOn: $loginSoundEnabled) {
                Label {
                    Text("Toggle Kawaii Madoka Music")
                        .foregroundStyle(palette.textPrimary)
                } icon: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(palette.primary)
                }
            }

            Picker("Theme", selection: Binding(
                get: { theme.theme },
                set: { theme.theme = $0 }
            )) {
                ForEach(AppTheme.allCases) { t in
                    Text(t.name).tag(t)
                }
            }
            .tint(palette.primary)
            .foregroundStyle(palette.textPrimary)
        } header: {
            Text("Preferences")
                .foregroundStyle(palette.textSecondary)
        }
        .listRowBackground(palette.card)
    }

    @ViewBuilder
    private func logoutSection(palette: ThemePalette) -> some View {
        Section {
            Button(role: .destructive) {
                // Placeholder logout
            } label: {
                Label {
                    Text("Log Out")
                        .foregroundStyle(palette.primary)
                } icon: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(palette.primary)
                }
            }
            .tint(palette.primary)
        }
        .listRowBackground(palette.card)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ThemeManager())
}
