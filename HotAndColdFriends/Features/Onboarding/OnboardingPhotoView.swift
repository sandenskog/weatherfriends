import SwiftUI
import PhotosUI

struct OnboardingPhotoView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var profileImage: UIImage?
    let displayName: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Välj profilbild")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Profilbilder hjälper dina vänner att känna igen dig. Du kan hoppa över detta steg.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Förhandsvisning av vald bild eller initial-avatar
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 140)

                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } else {
                    Text(initials)
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Välj bild", systemImage: "photo.on.rectangle")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    private var initials: String {
        let parts = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }
}

#Preview {
    @Previewable @State var item: PhotosPickerItem? = nil
    @Previewable @State var image: UIImage? = nil
    OnboardingPhotoView(selectedPhotoItem: $item, profileImage: $image, displayName: "Anna Karlsson")
}
