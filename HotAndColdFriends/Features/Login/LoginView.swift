import SwiftUI

/// Placeholder LoginView — implementeras fullt ut i Plan 02
/// Visar en enkel vy med appnamnet för att projektet ska kunna byggas
struct LoginView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Hot & Cold Friends")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Login")
                .font(.title2)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
