import Foundation

struct DemoFriendService {
    static let demoFriends: [Friend] = {
        var friends = [
            makeFriend(id: "demo-yuki",   name: "Yuki Tanaka",       city: "Tokyo, Japan",              lat: 35.6762,   lon: 139.6503, fav: true),
            makeFriend(id: "demo-amara",  name: "Amara Nkosi",       city: "Kapstaden, Sydafrika",       lat: -33.9249,  lon: 18.4241,  fav: true),
            makeFriend(id: "demo-emma",   name: "Emma Sullivan",     city: "New York, USA",              lat: 40.7128,   lon: -74.0060, fav: true),
            makeFriend(id: "demo-oliver", name: "Oliver Chen",       city: "Sydney, Australien",         lat: -33.8688,  lon: 151.2093, fav: false),
            makeFriend(id: "demo-fatima", name: "Fatima Al-Rashid",  city: "Dubai, UAE",                 lat: 25.2048,   lon: 55.2708,  fav: false),
            makeFriend(id: "demo-lars",   name: "Lars Eriksson",     city: "Stockholm, Sverige",         lat: 59.3293,   lon: 18.0686,  fav: false),
            makeFriend(id: "demo-marie",  name: "Marie Dubois",      city: "Paris, Frankrike",           lat: 48.8566,   lon: 2.3522,   fav: false),
            makeFriend(id: "demo-carlos", name: "Carlos Mendez",     city: "Buenos Aires, Argentina",    lat: -34.6037,  lon: -58.3816, fav: false),
        ]
        return friends
    }()

    private static func makeFriend(id: String, name: String, city: String, lat: Double, lon: Double, fav: Bool) -> Friend {
        var f = Friend(
            displayName: name,
            photoURL: nil,
            city: city,
            cityLatitude: lat,
            cityLongitude: lon,
            isFavorite: fav,
            isDemo: true
        )
        f.id = id
        return f
    }
}
