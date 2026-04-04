import SwiftUI

// MARK: - Spacing (8pt grid)

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let xl: CGFloat = 50
    static let round: CGFloat = 9999
}

// MARK: - Shadow Modifiers

extension View {
    func shadowSm() -> some View {
        shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
    func shadowMd() -> some View {
        shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
    func shadowLg() -> some View {
        shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 16)
    }
    func shadowGlowPrimary() -> some View {
        shadow(color: Color(hex: 0x1A85E0).opacity(0.25), radius: 12, x: 0, y: 8)
    }
    func shadowGlowAccent() -> some View {
        shadow(color: Color(hex: 0xF7C94A).opacity(0.25), radius: 12, x: 0, y: 8)
    }
}

// MARK: - GlassPanel

/// A glass-effect panel using .ultraThinMaterial with 28pt rounded corners.
struct GlassPanel<Content: View>: View {
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

// MARK: - GlassPill

/// A smaller glass pill with 50pt radius, for chips and compact controls.
struct GlassPill<Content: View>: View {
    var padding: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}

// MARK: - AtmosphereSegmentedPicker

/// Custom pill segmented picker that renders on a glass background.
/// Active segment gets a white fill; inactive segments are clear.
struct AtmosphereSegmentedPicker<T: Hashable>: View {
    let options: [(label: String, value: T)]
    @Binding var selection: T

    @Namespace private var pickerNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isSelected = selection == option.value

                Button {
                    withAnimation(reduceMotion
                        ? .easeInOut(duration: 0.2)
                        : .spring(response: 0.32, dampingFraction: 0.72)
                    ) {
                        selection = option.value
                    }
                } label: {
                    Text(option.label)
                        .font(.atmosphereSectionHeader)
                        .textCase(.uppercase)
                        .foregroundStyle(isSelected ? Color.primary : Color.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.white.opacity(0.9))
                                    .matchedGeometryEffect(id: "segmentBg", in: pickerNamespace)
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - TemperatureRingAvatar

/// Circular avatar with a thin temperature-zone colored ring.
struct TemperatureRingAvatar: View {
    let photoURL: String?
    let displayName: String
    let temperatureCelsius: Double?
    var size: CGFloat = 44

    private var zone: TemperatureZone {
        guard let c = temperatureCelsius else { return .arctic }
        return TemperatureZone(celsius: c)
    }

    private var initials: String {
        displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    var body: some View {
        ZStack {
            // Temperature ring
            Circle()
                .strokeBorder(zone.color, lineWidth: 2)
                .frame(width: size + 4, height: size + 4)

            // Photo or initials
            if let urlString = photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        initialsCircle
                    }
                }
                .frame(width: size, height: size)
            } else {
                initialsCircle
            }
        }
        .frame(width: size + 4, height: size + 4)
    }

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(zone.gradient)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - ZoneDivider

/// Horizontal section divider with a colored zone dot and label.
struct ZoneDivider: View {
    let zone: TemperatureZone
    let friendCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(zone.color)
                .frame(width: 6, height: 6)

            Text(zone.label.uppercased())
                .font(.atmosphereSectionHeader)
                .foregroundStyle(Color.white.opacity(0.65))

            Text("· \(friendCount)")
                .font(.atmosphereSectionHeader)
                .foregroundStyle(Color.white.opacity(0.40))

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - AtmosphereTabBar

/// Custom tab bar with .ultraThinMaterial, active tab indicated by a zone-colored dot.
struct AtmosphereTabBar: View {
    @Binding var selectedTab: Int
    let items: [(icon: String, label: String)]
    var accentColor: Color = .white

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let isSelected = selectedTab == index
                Button {
                    selectedTab = index
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: items[index].icon)
                            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.5))

                        Text(items[index].label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.5))

                        // Active dot
                        Circle()
                            .fill(isSelected ? accentColor : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
