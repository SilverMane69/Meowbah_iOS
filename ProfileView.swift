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

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        NavigationStack {
            Form {
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
                    .listRowBackground(palette.card)
                }

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
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(palette.primary)
        }
        .tint(palette.primary)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ThemeManager())
}
