import SwiftUI

struct OnboardingNameView: View {
    @Binding var displayName: String
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Vad heter du?")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Ditt namn visas för dina vänner i appen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            TextField("Ditt namn", text: $displayName)
                .font(.title3)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .autocorrectionDisabled()
                .focused($isNameFieldFocused)
                .submitLabel(.next)

            Spacer()
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    OnboardingNameView(displayName: $name)
}
