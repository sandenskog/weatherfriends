import SwiftUI

struct ContactImportRow: View {
    let contact: ImportableContact
    let isSelected: Bool
    let isAlreadyAdded: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isAlreadyAdded ? Color(.systemGray4) : (isSelected ? .blue : Color(.systemGray3)))

            // Profilbild eller initialer
            if let imageData = contact.thumbnailImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    Text(initials(for: contact.fullName))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }

            // Namn och stad-hint
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.fullName)
                    .font(.body)
                    .foregroundStyle(isAlreadyAdded ? .secondary : .primary)
                if isAlreadyAdded {
                    Text("Redan tillagd")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !contact.locationHint.isEmpty {
                    Text(contact.locationHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(isAlreadyAdded ? 0.6 : 1.0)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String((parts[0].first ?? Character(" "))).uppercased() +
                   String((parts[1].first ?? Character(" "))).uppercased()
        } else if let first = parts.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }
}
