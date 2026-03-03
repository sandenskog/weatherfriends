import FirebaseFirestore

enum MessageType: String, Codable {
    case text
    case weatherSticker
}

struct WeatherStickerData: Codable {
    var city: String
    var countryCode: String
    var temperatureCelsius: Double
    var conditionSymbol: String      // SF Symbol-namn (t.ex. "sun.max")
    var ownerUid: String             // vems väder det är
}

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    var senderId: String
    var type: MessageType
    var text: String?               // null om type == .weatherSticker
    var weatherData: WeatherStickerData?  // null om type == .text
    @ServerTimestamp var sentAt: Timestamp?
}
