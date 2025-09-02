import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Inputs
    var onLogin: ((String, String) async throws -> Void)?
    var onGuest: (() -> Void)?

    // MARK: - UI State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Music toggle mirrors Preferences
    @AppStorage("loginSoundEnabled") private var loginSoundEnabled: Bool = true

    // Use same audio as ProfileView
    private let audioName = "梶浦 由記 - Sis puella magica!"
    private let audioExt = "m4a"

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isLoading
    }

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Logo
                    logo(palette: palette)
                        .padding(.top, 32)

                    // Card
                    VStack(spacing: 16) {
                        Text("Welcome back!")
                            .font(.title2).bold()
                            .foregroundStyle(palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        emailField(palette: palette)
                        passwordField(palette: palette)

                        Button {
                            Task { await loginTapped() }
                        } label: {
                            HStack {
                                if isLoading { ProgressView().tint(.white) }
                                Text("Log In").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(canSubmit ? LinearGradient(
                                        colors: [palette.primary, palette.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : LinearGradient(
                                        colors: [palette.primary.opacity(0.5), palette.secondary.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit)

                        // Guest button
                        Button {
                            onGuest?()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "pawprint.fill")
                                Text("Continue as Guest").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(palette.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(palette.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(palette.primary.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Music toggle
                        Toggle(isOn: $loginSoundEnabled) {
                            Label {
                                Text("Kawaii Madoka Music")
                                    .foregroundStyle(palette.textPrimary)
                            } icon: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(palette.primary)
                            }
                        }
                        .tint(palette.primary)
                        .onChange(of: loginSoundEnabled) { enabled in
                            if enabled {
                                AudioPlayback.shared.ensureStartedLoop(named: audioName, ext: audioExt, respectSilent: true)
                                AudioPlayback.shared.resume()
                            } else {
                                AudioPlayback.shared.pause()
                            }
                        }

                        if let message = errorMessage, !message.isEmpty {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(Color.red)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(palette.card)
                    )
                    .shadow(color: palette.shadow.opacity(0.08), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .tint(palette.primary)
        .onAppear {
            // Start or pause audio based on saved toggle
            if loginSoundEnabled {
                AudioPlayback.shared.ensureStartedLoop(named: audioName, ext: audioExt, respectSilent: true)
                AudioPlayback.shared.resume()
            } else {
                AudioPlayback.shared.pause()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func logo(palette: ThemePalette) -> some View {
        VStack(spacing: 12) {
            if let uiImage = UIImage(named: "LoginLogo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .shadow(color: palette.shadow.opacity(0.15), radius: 10, x: 0, y: 6)
                    .accessibilityLabel("Meowbah")
            } else {
                // Fallback if asset missing
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [palette.primary, palette.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "cat.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func emailField(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.footnote).bold()
                .foregroundStyle(palette.textSecondary)
            TextField("you@example.com", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.25))
                )
        }
    }

    @ViewBuilder
    private func passwordField(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.footnote).bold()
                .foregroundStyle(palette.textSecondary)
            HStack {
                Group {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .onSubmit { Task { await loginTapped() } }
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .onSubmit { Task { await loginTapped() } }
                    }
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25))
            )
        }
    }

    // MARK: - Actions

    @MainActor
    private func loginTapped() async {
        guard canSubmit else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await onLogin?(email, password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView(
        onLogin: { _, _ in try await Task.sleep(nanoseconds: 200_000_000) },
        onGuest: {}
    )
    .environmentObject(ThemeManager())
}
