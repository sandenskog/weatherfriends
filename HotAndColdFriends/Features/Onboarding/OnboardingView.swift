import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserService.self) private var userService
    @Environment(FriendService.self) private var friendService
    @State private var viewModel = OnboardingViewModel()

    private let stepTitles = ["Ditt namn", "Profilbild", "Din stad", "Dina vänner"]

    var body: some View {
        ZStack {
            // Sky background — sunny for onboarding
            AtmosphereSkyBackground(mood: .sunny)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(0..<stepTitles.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= viewModel.currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(height: 4)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        }
                    }
                    .padding(.horizontal)

                    Text("Steg \(viewModel.currentStep + 1) av \(stepTitles.count)")
                        .font(.bubbleCaption)
                        .foregroundStyle(Color.atmosphereTextOnSkySecondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 8)

                // Step content — on glass sheet
                VStack(spacing: 0) {
                    TabView(selection: $viewModel.currentStep) {
                        OnboardingNameView(displayName: $viewModel.displayName)
                            .tag(0)

                        OnboardingPhotoView(
                            selectedPhotoItem: $viewModel.selectedPhotoItem,
                            profileImage: $viewModel.profileImage,
                            displayName: viewModel.displayName
                        )
                        .tag(1)

                        OnboardingLocationView(
                            selectedCity: $viewModel.selectedCity,
                            selectedCityLatitude: $viewModel.selectedCityLatitude,
                            selectedCityLongitude: $viewModel.selectedCityLongitude
                        )
                        .tag(2)

                        OnboardingFavoritesView(pendingFriends: $viewModel.pendingFriends)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding(.bottom, 32)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 0)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation Buttons

    @ViewBuilder
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if viewModel.currentStep == 3 {
                HStack(spacing: 12) {
                    Button {
                        viewModel.pendingFriends = []
                        Task { await completeOnboarding() }
                    } label: {
                        Text("Hoppa över")
                            .font(.bubbleButton)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        Task { await completeOnboarding() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().tint(.white).frame(maxWidth: .infinity).padding()
                        } else {
                            Text("Slutför")
                                .font(.bubbleButton)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.bubblePrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal)

            } else if viewModel.currentStep == 2 {
                Button {
                    withAnimation { viewModel.currentStep += 1 }
                } label: {
                    Text("Fortsätt")
                        .font(.bubbleButton)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(viewModel.canProceedFromLocation ? Color.bubblePrimary : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!viewModel.canProceedFromLocation)
                .padding(.horizontal)

            } else if viewModel.currentStep == 1 {
                HStack(spacing: 12) {
                    Button {
                        withAnimation { viewModel.currentStep += 1 }
                    } label: {
                        Text("Hoppa över")
                            .font(.bubbleButton)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        withAnimation { viewModel.currentStep += 1 }
                    } label: {
                        Text("Fortsätt")
                            .font(.bubbleButton)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.bubblePrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

            } else {
                Button {
                    withAnimation { viewModel.currentStep += 1 }
                } label: {
                    Text("Fortsätt")
                        .font(.bubbleButton)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(viewModel.canProceedFromName ? Color.bubblePrimary : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!viewModel.canProceedFromName)
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func completeOnboarding() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            viewModel.errorMessage = "Inloggningsfel — vänligen logga in igen."
            return
        }
        do {
            try await viewModel.completeOnboarding(uid: uid, authManager: authManager, userService: userService, friendService: friendService)
        } catch {
            viewModel.errorMessage = "Kunde inte spara profilen: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
        .environment(UserService())
        .environment(FriendService())
}
