import SwiftUI
import FirebaseFirestore

struct ChatBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let senderName: String?
    let onReport: () -> Void
    let onBlock: (() -> Void)?

    @State private var showReportAlert = false
    @State private var showBlockAlert = false

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                // Avsändarnamn i gruppchatt (ej för current user)
                if !isCurrentUser, let name = senderName {
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                bubbleContent
                    .contextMenu {
                        contextMenuItems
                    }

                // Tidsstämpel
                Text(formattedTime(message.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isCurrentUser { Spacer(minLength: 60) }
        }
        .alert("Rapportera meddelande", isPresented: $showReportAlert) {
            Button("Rapportera", role: .destructive) {
                onReport()
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Det här meddelandet kommer rapporteras till vårt team för granskning.")
        }
        .alert("Blockera användare", isPresented: $showBlockAlert) {
            Button("Blockera", role: .destructive) {
                onBlock?()
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            if let name = senderName {
                Text("Blockera \(name)? Du kommer inte se deras meddelanden.")
            } else {
                Text("Blockera den här användaren? Du kommer inte se deras meddelanden.")
            }
        }
    }

    // MARK: - Bubbla

    @ViewBuilder
    private var bubbleContent: some View {
        if message.type == .weatherSticker, let weatherData = message.weatherData {
            WeatherStickerView(weatherData: weatherData)
        } else if isCurrentUser {
            Text(message.text ?? "")
                .font(.bubbleBody)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(LinearGradient.chatMine)
                .clipShape(UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 20,
                        bottomLeading: 20,
                        bottomTrailing: 6,
                        topTrailing: 20
                    )
                ))
        } else {
            Text(message.text ?? "")
                .font(.bubbleBody)
                .foregroundStyle(Color.bubbleTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.bubbleSurface)
                .overlay(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 6,
                            bottomLeading: 20,
                            bottomTrailing: 20,
                            topTrailing: 20
                        )
                    )
                    .strokeBorder(Color.bubbleBorder, lineWidth: 1)
                )
                .clipShape(UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 6,
                        bottomLeading: 20,
                        bottomTrailing: 20,
                        topTrailing: 20
                    )
                ))
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            showReportAlert = true
        } label: {
            Label("Rapportera", systemImage: "flag")
        }

        if !isCurrentUser {
            Button(role: .destructive) {
                showBlockAlert = true
            } label: {
                Label("Blockera användare", systemImage: "hand.raised")
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ timestamp: Timestamp?) -> String {
        guard let timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp.dateValue())
    }
}
