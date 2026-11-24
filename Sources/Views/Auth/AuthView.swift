import SwiftUI
import AuthenticationServices
import Supabase

struct AuthView: View {
    @Environment(SupabaseSyncService.self) private var syncService
    @Environment(\.openURL) private var openURL

    @State private var isSignUp: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 32)

                // Header & Brand Logo
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient.cardGradient)
                            .frame(width: 64, height: 64)
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(LinearGradient.topLightBevel, lineWidth: 1.5))
                            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.cobaltBlue)
                    }

                    VStack(spacing: 4) {
                        Text("Habit Tracker")
                            .font(.hostGrotesk(.bold, size: 28))
                            .foregroundStyle(Color.primaryText)
                            .letterpress(isLight: false)

                        Text("Build discipline, break barriers.")
                            .font(.hostGrotesk(.regular, size: 14))
                            .foregroundStyle(Color.secondaryText)
                            .letterpress(isLight: false)
                    }
                }

                // Mode Switcher Pill (Sign In / Sign Up)
                HStack(spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp = false
                            errorMessage = nil
                        }
                    } label: {
                        Text("Sign In")
                            .font(.hostGrotesk(.medium, size: 14))
                            .foregroundStyle(!isSignUp ? Color.cobaltLabel : Color.primaryText)
                            .letterpress(isLight: !isSignUp)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if !isSignUp {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient.cobaltEnamel)
                                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.65), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
                                            .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 2, x: 0, y: 1)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }
                    .buttonStyle(SkeuomorphicButtonStyle())

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp = true
                            errorMessage = nil
                        }
                    } label: {
                        Text("Create Account")
                            .font(.hostGrotesk(.medium, size: 14))
                            .foregroundStyle(isSignUp ? Color.cobaltLabel : Color.primaryText)
                            .letterpress(isLight: isSignUp)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if isSignUp {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient.cobaltEnamel)
                                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.65), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
                                            .shadow(color: Color.cobaltBlue.opacity(0.35), radius: 2, x: 0, y: 1)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }
                    .buttonStyle(SkeuomorphicButtonStyle())
                }
                .padding(4)
                .skeuomorphicWell(cornerRadius: 12)

                    // Error Banner
                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.red)
                            Text(errorMessage)
                                .font(.hostGrotesk(.regular, size: 13))
                                .foregroundStyle(Color.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Main Form Card
                    VStack(spacing: 14) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Display Name")
                                    .font(.hostGrotesk(.medium, size: 12))
                                    .foregroundStyle(Color.secondaryText)
                                    .letterpress(isLight: false)

                                TextField("e.g. Alex Rivera", text: $displayName)
                                    .font(.hostGrotesk(.regular, size: 15))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .skeuomorphicWell(cornerRadius: 10)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.hostGrotesk(.medium, size: 12))
                                .foregroundStyle(Color.secondaryText)
                                .letterpress(isLight: false)

                            TextField("name@example.com", text: $email)
                                .font(.hostGrotesk(.regular, size: 15))
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .skeuomorphicWell(cornerRadius: 10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.hostGrotesk(.medium, size: 12))
                                .foregroundStyle(Color.secondaryText)
                                .letterpress(isLight: false)

                            SecureField("••••••••", text: $password)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .skeuomorphicWell(cornerRadius: 10)
                        }

                        Spacer().frame(height: 4)

                        // Submit Button
                        Button {
                            handleSubmit()
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(Color.cobaltLabel)
                                }
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.hostGrotesk(.semibold, size: 15))
                                    .foregroundStyle(Color.cobaltLabel)
                                    .letterpress(isLight: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .skeuomorphicCobaltButton(cornerRadius: 12)
                        }
                        .buttonStyle(SkeuomorphicButtonStyle())
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(18)
                    .skeuomorphicCard(cornerRadius: 16)

                    // OR Divider
                    HStack(spacing: 12) {
                        EngravedDivider()
                        Text("OR CONTINUE WITH")
                            .font(.hostGrotesk(.semibold, size: 11))
                            .foregroundStyle(Color.mutedText)
                            .letterpress(isLight: false)
                            .fixedSize()
                        EngravedDivider()
                    }
                    .padding(.vertical, 4)

                    // OAuth Providers (Supabase OAuth)
                    VStack(spacing: 10) {
                        OAuthButton(
                            title: "Continue with Google",
                            iconName: "globe.americas.fill",
                            onClick: { handleOAuth(provider: .google) }
                        )

                        OAuthButton(
                            title: "Continue with Apple",
                            iconName: "applelogo",
                            onClick: { handleOAuth(provider: .apple) }
                        )

                        OAuthButton(
                            title: "Continue with GitHub",
                            iconName: "chevron.left.forwardslash.chevron.right",
                            onClick: { handleOAuth(provider: .github) }
                        )
                    }

                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, 20)
            }
            .paperBackground()
    }

    // MARK: - Actions

    private func handleSubmit() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isSignUp {
                    try await syncService.signUp(
                        email: email,
                        password: password,
                        displayName: displayName.isEmpty ? "Habit Tracker" : displayName
                    )
                } else {
                    try await syncService.signIn(
                        email: email,
                        password: password
                    )
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func handleOAuth(provider: Provider) {
        Task {
            do {
                let authURL = try await syncService.getOAuthURL(provider: provider)
                await MainActor.run {
                    openURL(authURL)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - OAuth Button Component

private struct OAuthButton: View {
    let title: String
    let iconName: String
    let onClick: () -> Void

    var body: some View {
        Button {
            onClick()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 22)

                Text(title)
                    .font(.hostGrotesk(.medium, size: 14))
                    .foregroundStyle(Color.primaryText)
                    .letterpress(isLight: false)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .skeuomorphicCard(cornerRadius: 12)
        }
        .buttonStyle(SkeuomorphicButtonStyle())
    }
}
