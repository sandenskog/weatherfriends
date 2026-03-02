import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserService.self) private var userService
    @State private var viewModel = OnboardingViewModel()

    private let stepTitles = ["Ditt namn", "Profilbild", "Din stad"]

    var body: some View {
        VStack(spacing: 0) {
            // Progress-indikator
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= viewModel.currentStep ? Color.black : Color(.systemGray4))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    }
                }
                .padding(.horizontal)

                Text("Steg \(viewModel.currentStep + 1) av 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Steg-innehåll
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
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

            // Navigationsknappar
            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if viewModel.currentStep == 2 {
                    // Sista steget: Slutför
                    Button {
                        Task { await completeOnboarding() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Slutför")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(viewModel.canProceedFromLocation ? Color.black : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!viewModel.canProceedFromLocation || viewModel.isLoading)
                    .padding(.horizontal)
                } else if viewModel.currentStep == 1 {
                    // Foto-steget: Hoppa över + Fortsätt
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { viewModel.currentStep += 1 }
                        } label: {
                            Text("Hoppa över")
                                .font(.body)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            withAnimation { viewModel.currentStep += 1 }
                        } label: {
                            Text("Fortsätt")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Namn-steget: Fortsätt (kräver namn)
                    Button {
                        withAnimation { viewModel.currentStep += 1 }
                    } label: {
                        Text("Fortsätt")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(viewModel.canProceedFromName ? Color.black : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!viewModel.canProceedFromName)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func completeOnboarding() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            viewModel.errorMessage = "Inloggningsfel — vänligen logga in igen."
            return
        }
        do {
            try await viewModel.completeOnboarding(uid: uid, authManager: authManager, userService: userService)
        } catch {
            viewModel.errorMessage = "Kunde inte spara profilen: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
        .environment(UserService())
}
