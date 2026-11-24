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
        ZStack {
            Color.pageGround
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 32)

                    // Header & Brand Logo
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardSurface)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.hairline, lineWidth: 1)
                                )

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.cobaltBlue)
                        }

                        VStack(spacing: 4) {
                            Text("Habit Tracker")
                                .font(.hostGrotesk(.bold, size: 28))
                                .foregroundStyle(Color.primaryText)

                            Text("Build discipline, break barriers.")
                                .font(.hostGrotesk(.regular, size: 14))
                                .foregroundStyle(Color.secondaryText)
                        }
                    }

                    // Mode Switcher Pill (Sign In / Sign Up)
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp = false
                                errorMessage = nil
                            }
                        } label: {
                            Text("Sign In")
                                .font(.hostGrotesk(.medium, size: 14))
                                .foregroundStyle(!isSignUp ? Color.primaryText : Color.mutedText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    !isSignUp ? Color.pageGround : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp = true
                                errorMessage = nil
                            }
                        } label: {
                            Text("Create Account")
                                .font(.hostGrotesk(.medium, size: 14))
                                .foregroundStyle(isSignUp ? Color.primaryText : Color.mutedText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    isSignUp ? Color.pageGround : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(Color.cardSurface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.hairline, lineWidth: 1)
                    )

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

                                TextField("e.g. Alex Rivera", text: $displayName)
                                    .font(.hostGrotesk(.regular, size: 15))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.pageGround)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.hairline, lineWidth: 1)
                                    )
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.hostGrotesk(.medium, size: 12))
                                .foregroundStyle(Color.secondaryText)

                            TextField("name@example.com", text: $email)
                                .font(.hostGrotesk(.regular, size: 15))
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.pageGround)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.hairline, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.hostGrotesk(.medium, size: 12))
                                .foregroundStyle(Color.secondaryText)

                            SecureField("••••••••", text: $password)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.pageGround)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.hairline, lineWidth: 1)
                                )
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
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cobaltBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(18)
                    .background(Color.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.hairline, lineWidth: 1)
                    )

                    // OR Divider
                    HStack {
                        Rectangle()
                            .fill(Color.hairline)
                            .frame(height: 1)
                        Text("OR CONTINUE WITH")
                            .font(.hostGrotesk(.semibold, size: 11))
                            .foregroundStyle(Color.mutedText)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.hairline)
                            .frame(height: 1)
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
        }
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

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mutedText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
