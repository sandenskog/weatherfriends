import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            // Mjuk gradient bakgrund: vitt till ljusblått
            LinearGradient(
                colors: [Color.white, Color.blue.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Header: logotyp och tagline
                VStack(spacing: 12) {
                    Image("LogoHorizontal")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 220)
                        .padding(.bottom, 4)

                    Text("Se vädret hos dina vänner")
                        .font(.bubbleH3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Login-knappar staplade vertikalt
                VStack(spacing: 12) {
                    // Sign in with Apple
                    AppleLoginButton(
                        isLoading: viewModel.loadingProvider == "apple",
                        isDisabled: viewModel.isLoading && viewModel.loadingProvider != "apple"
                    ) {
                        Task {
                            await viewModel.signInWithApple(authManager: authManager)
                        }
                    }

                    // Google Sign-In
                    SocialLoginButton(
                        provider: "google",
                        title: "Fortsätt med Google",
                        systemImage: nil,
                        imageName: "google-logo",
                        backgroundColor: Color.white,
                        foregroundColor: Color.black.opacity(0.85),
                        borderColor: Color.gray.opacity(0.3),
                        isLoading: viewModel.loadingProvider == "google",
                        isDisabled: viewModel.isLoading && viewModel.loadingProvider != "google"
                    ) {
                        Task {
                            await viewModel.signInWithGoogle(authManager: authManager)
                        }
                    }

                    // Facebook Login
                    SocialLoginButton(
                        provider: "facebook",
                        title: "Fortsätt med Facebook",
                        systemImage: nil,
                        imageName: "facebook-logo",
                        backgroundColor: Color(red: 0.231, green: 0.349, blue: 0.596),
                        foregroundColor: Color.white,
                        borderColor: Color.clear,
                        isLoading: viewModel.loadingProvider == "facebook",
                        isDisabled: viewModel.isLoading && viewModel.loadingProvider != "facebook"
                    ) {
                        Task {
                            await viewModel.signInWithFacebook(authManager: authManager)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .alert(
            "Inloggningen misslyckades",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Apple Login Button

private struct AppleLoginButton: View {
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.white)
                        Text("Fortsätt med Apple")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .frame(height: 52)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Generic Social Login Button

private struct SocialLoginButton: View {
    let provider: String
    let title: String
    let systemImage: String?
    let imageName: String?
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                } else {
                    HStack(spacing: 8) {
                        // Logga-bild (inline SF Symbol fallback om bilden saknas)
                        if let systemImage = systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(foregroundColor)
                        } else if let imageName = imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }

                        Text(title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(foregroundColor)
                    }
                }
            }
            .frame(height: 52)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
