//
//  LoginView.swift
//  Meowbah
//
//  Created by Ryan Reid on 25/08/2025.
//

import SwiftUI

struct LoginView: View {
    var onAuthenticated: (() -> Void)?

    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header(palette: palette)
                    formFields(palette: palette)
                    primaryActions(palette: palette)
                    footer(palette: palette)
                }
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(palette.background.ignoresSafeArea())
            // Removed .navigationTitle("Welcome")
        }
        .tint(palette.primary)
    }

    private func header(palette: ThemePalette) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.primary, palette.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                // Replaced SF Symbol with branded image from the asset catalog.
                Image("LoginLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .accessibilityLabel("Meowbah logo")
            }
            Text("Meowbah")
                .font(.largeTitle).bold()
                .foregroundStyle(palette.textPrimary)
            Text("Cute videos, cozy vibes.")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.top, 36)
    }

    private func formFields(palette: ThemePalette) -> some View {
        VStack(spacing: 14) {
            if let errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(palette.primary)
                    Text(errorMessage)
                        .foregroundStyle(palette.textSecondary)
                        .font(.footnote)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(palette.card)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.footnote).bold()
                    .foregroundStyle(palette.textPrimary)
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(palette.primary)
                    TextField("you@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(palette.textPrimary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(palette.card)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.footnote).bold()
                    .foregroundStyle(palette.textPrimary)
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(palette.primary)
                    Group {
                        if isSecure {
                            SecureField("••••••••", text: $password)
                                .textContentType(.password)
                        } else {
                            TextField("Your password", text: $password)
                                .textContentType(.password)
                        }
                    }
                    .foregroundStyle(palette.textPrimary)
                    Button {
                        isSecure.toggle()
                    } label: {
                        Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(palette.card)
                )
            }
        }
    }

    private func primaryActions(palette: ThemePalette) -> some View {
        VStack(spacing: 12) {
            Button {
                Task { await handleLogin() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(Color.white)
                    }
                    Text(isLoading ? "Logging In..." : "Log In")
                        .font(.headline)
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
            .disabled(isLoading)

            Button {
                handleGuestLogin()
            } label: {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                    Text("Continue as Guest")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.primary.opacity(0.6), lineWidth: 1.5)
                )
                .foregroundStyle(palette.textPrimary)
            }
            .disabled(isLoading)
        }
        .padding(.top, 8)
    }

    private func footer(palette: ThemePalette) -> some View {
        VStack(spacing: 8) {
            Button {
                // Forgot password flow
            } label: {
                Text("Forgot password?")
                    .font(.footnote)
                    .foregroundStyle(palette.primary)
            }

            HStack(spacing: 4) {
                Text("Don’t have an account?")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                Button {
                    // Sign up flow
                } label: {
                    Text("Sign up")
                        .font(.footnote).bold()
                        .foregroundStyle(palette.primary)
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func validate() -> String? {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter your email."
        }
        if password.isEmpty {
            return "Please enter your password."
        }
        return nil
    }

    private func handleGuestLogin() {
        errorMessage = nil
        onAuthenticated?()
    }

    private func handleLogin() async {
        if let msg = validate() {
            errorMessage = msg
            return
        }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        onAuthenticated?()
    }
}

#Preview {
    LoginView()
        .environmentObject(ThemeManager())
}
