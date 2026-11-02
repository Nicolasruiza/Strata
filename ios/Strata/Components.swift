import SwiftUI

// MARK: text styles (style.css .label .name .meta .small .title2 .p)

extension View {
    func labelStyle(_ color: Color = Theme.muted) -> some View {
        self.font(.system(size: Theme.Size.label, weight: .semibold))
            .tracking(Theme.Size.label * 0.16).textCase(.uppercase).foregroundStyle(color)
    }
    func nameStyle(_ size: CGFloat = Theme.Size.name, color: Color = .white) -> some View {
        self.font(.system(size: size, weight: .semibold)).foregroundStyle(color)
    }
    func metaStyle() -> some View { self.font(.system(size: Theme.Size.meta)).foregroundStyle(Theme.muted) }
    func smallStyle() -> some View { self.font(.system(size: Theme.Size.small)).foregroundStyle(Theme.muted) }
    func title2Style(_ size: CGFloat = Theme.Size.title2) -> some View {
        self.font(.system(size: size, weight: .heavy)).tracking(-size * 0.02).foregroundStyle(.white)
    }
    func bodyStyle() -> some View {
        self.font(.system(size: Theme.Size.body)).foregroundStyle(Theme.soft).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
    }
}

/// `.card`
struct CardStyle: ViewModifier {
    var tight = false
    var border: Color = Theme.line
    var dashed = false
    var fill: AnyShapeStyle = AnyShapeStyle(Theme.glass)
    func body(content: Content) -> some View {
        content
            .padding(tight ? 12 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(border, style: StrokeStyle(lineWidth: 1, dash: dashed ? [5, 4] : [])))
    }
}
extension View {
    func card(tight: Bool = false, border: Color = Theme.line, dashed: Bool = false) -> some View {
        modifier(CardStyle(tight: tight, border: border, dashed: dashed))
    }
}

// MARK: buttons (.btn and variants)

enum BtnKind { case plain, primary, violet, violetFlat, coral, mint }

struct StrataButtonStyle: ButtonStyle {
    var kind: BtnKind = .plain
    var small = false
    var color: Color?               // explicit solid fill (home sessions use the ring colour)
    var hPad: CGFloat?              // content-width button with this horizontal padding (`padding:0 22px`)
    var height: CGFloat?            // explicit height (`height:auto` next to a field = the field's height)
    func makeBody(configuration: Configuration) -> some View {
        let h = height ?? (small ? Theme.Size.buttonSmallHeight : Theme.Size.buttonHeight)
        let r = small ? Theme.Radius.buttonSmall : Theme.Radius.button
        configuration.label
            .font(.system(size: small ? 14 : Theme.Size.button, weight: .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, hPad ?? 0)
            .frame(maxWidth: hPad == nil ? .infinity : nil, minHeight: h, maxHeight: h)
            .background(RoundedRectangle(cornerRadius: r).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: r).strokeBorder(border, lineWidth: 1))
            .shadow(color: shadow, radius: 14, y: 10)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
    private var fg: Color {
        if color != nil { return Color(hex: "#0E1018") }
        switch kind { case .primary: return Color(hex: "#0E1018"); case .mint: return Color(hex: "#08210F"); default: return .white }
    }
    private var fill: AnyShapeStyle {
        if let c = color { return AnyShapeStyle(c) }
        switch kind {
        case .plain: return AnyShapeStyle(Color.white.opacity(0.08))
        case .primary: return AnyShapeStyle(Color(hex: "#F4F5F8"))
        case .violet: return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#AC9EFF"), Color(hex: "#7C6CF0")], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .violetFlat: return AnyShapeStyle(Color(hex: "#9C8CFF").opacity(0.85))      // `Machine busy`: inline background
        case .coral: return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#FF8A6E"), Color(hex: "#F0583A")], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .mint: return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#6EE7A0"), Color(hex: "#2FBF68")], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
    private var border: Color { (kind == .plain && color == nil) ? Color.white.opacity(0.16) : .clear }
    private var shadow: Color {
        switch kind { case .violet, .violetFlat: return Color(hex: "#7C6CF0").opacity(0.4); case .coral: return Color(hex: "#F0583A").opacity(0.35); default: return .clear }
    }
}

/// `.link`
struct LinkButtonStyle: ButtonStyle {
    var color: Color = Theme.muted
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            .underline(true).padding(10).opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: hero (header with the mountain photo)

struct Hero: View {
    var eyebrow: String?
    var title: String
    var titleAttr: AttributedString?
    var titleSize: CGFloat = Theme.Size.h1
    var sub: String?
    var tall = false
    var short = false
    var image = "mountain"
    var brand = true              // heroes with a back button replace the logo (`o.left`)
    @Environment(\.safeTop) private var safeTop

    var body: some View {
        let h: CGFloat = (tall ? 310 : short ? 200 : 250)
        ZStack(alignment: .bottomLeading) {
            Theme.bg2
            Color.clear.frame(height: h + safeTop).overlay(BundleImage(name: image)).clipped()
            LinearGradient(stops: [.init(color: Theme.bg.opacity(0.25), location: 0), .init(color: Theme.bg.opacity(0.35), location: 0.45), .init(color: Theme.bg, location: 1)],
                           startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) { LogoMark(); Text("Strata").font(.system(size: 20, weight: .bold)).tracking(-0.2) }
                    .opacity(brand ? 1 : 0).frame(minHeight: 44)
                    .padding(.top, 14 + safeTop)
                Spacer(minLength: 0)
                if let e = eyebrow {
                    Text(e).font(.system(size: 11, weight: .semibold)).tracking(2.2).textCase(.uppercase).foregroundStyle(Color.white.opacity(0.82))
                }
                Group { if let a = titleAttr { Text(a) } else { Text(title) } }
                    .font(.system(size: titleSize, weight: .heavy)).tracking(-titleSize * 0.02).lineSpacing(0)
                    .padding(.top, 6).padding(.bottom, 4).fixedSize(horizontal: false, vertical: true)
                if let s = sub { Text(s).font(.system(size: 15)).foregroundStyle(Theme.soft).fixedSize(horizontal: false, vertical: true) }
            }
            .padding(.horizontal, 20).padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: h + safeTop)
        .foregroundStyle(.white)
    }
}

/// An image from the web's `img/` folder, bundled as a folder reference.
struct BundleImage: View {
    let name: String
    var body: some View {
        if let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "img"),
           let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            Color(hex: "#1b1e28")
        }
    }
}

/// `.thumb`
struct Thumb: View {
    let path: String?             // "img/x.jpg" from Catalog.imageName
    var size: CGFloat = 56
    var radius: CGFloat = 14
    var body: some View {
        Group {
            if let p = path { BundleImage(name: ((p as NSString).lastPathComponent as NSString).deletingPathExtension) }
            else { Color(hex: "#1b1e28") }
        }
        .frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: safe area top, because the hero draws under the status bar

private struct SafeTopKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }
extension EnvironmentValues {
    var safeTop: CGFloat { get { self[SafeTopKey.self] } set { self[SafeTopKey.self] = newValue } }
}

// MARK: toast

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "#0E1018"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(Capsule().fill(Color(hex: "#F4F5F8")))
            .shadow(color: .black.opacity(0.4), radius: 15, y: 10)
            .frame(maxWidth: 340)
    }
}

// MARK: rich text: **bold** from the shared logic copy, bold runs white like `.p b`

struct RichText: View {
    let markdown: String
    var body: some View {
        var a = (try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(markdown)
        for run in a.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            a[run.range].foregroundColor = .white
        }
        return Text(a)
    }
}

/// `.seg` segmented control
struct Seg<Value: Hashable>: View {
    let items: [(Value, String)]
    let selected: Value?
    let onPick: (Value) -> Void
    var body: some View {
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { i in
                let (v, label) = items[i]
                Button { onPick(v) } label: {
                    Text(label).font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selected == v ? Color.white : Theme.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(selected == v ? Color.white.opacity(0.14) : .clear))
                }.buttonStyle(.plain)
            }
        }
        .padding(4).background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
    }
}

/// `.opt` rows in sheets
struct OptRow<Trailing: View>: View {
    let title: String
    var meta: String?
    var on = false
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).nameStyle()
                if let m = meta { Text(m).metaStyle() }
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(on ? Theme.violet.opacity(0.1) : Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(on ? Theme.violet : Theme.line))
        .contentShape(Rectangle())
    }
}

private struct SheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Bottom sheet chrome (`.sheet`): as tall as its content, up to 86% of the screen.
struct SheetChrome<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var height: CGFloat = 0
    var body: some View {
        let cap = UIScreen.main.bounds.height * 0.86
        ScrollView {
            VStack(alignment: .leading, spacing: 0) { content() }
                .padding(.horizontal, 16).padding(.top, 22).padding(.bottom, 20)
                .background(GeometryReader { g in Color.clear.preference(key: SheetHeightKey.self, value: g.size.height) })
        }
        .onPreferenceChange(SheetHeightKey.self) { height = $0 }
        .background(Color(hex: "#171A26").ignoresSafeArea())
        .presentationDetents(height > 0 ? [.height(min(height, cap))] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: "#171A26"))
        .preferredColorScheme(.dark)
    }
}

/// `.step` number/text field row
struct StepField: View {
    let title: String?
    var placeholder = ""
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var width: CGFloat? = nil
    var big = false
    var alignRight = true
    var body: some View {
        HStack {
            if let t = title { Text(t).nameStyle() }
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.dim))
                .keyboardType(keyboard)
                .multilineTextAlignment(alignRight ? .trailing : .center)
                .font(.system(size: big ? 26 : 17, weight: big ? .heavy : .semibold))
                .frame(width: width)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.25)))
    }
}

/// `.sw`: 52 × 32 switch, light track and dark knob when on.
struct WebSwitch: View {
    @Binding var isOn: Bool
    var label = ""
    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: .leading) {
                Capsule().fill(isOn ? Color(hex: "#F4F5F8") : Color.white.opacity(0.16))
                Circle().fill(isOn ? Color(hex: "#0E1018") : Color.white).frame(width: 26, height: 26).padding(.leading, isOn ? 23 : 3)
            }
            .frame(width: 52, height: 32).animation(.easeOut(duration: 0.18), value: isOn)
        }
        .buttonStyle(.plain).accessibilityLabel(label)
        .accessibilityAddTraits(.isButton).accessibilityValue(isOn ? "on" : "off")
    }
}

/// The web's accent panels: a radial glow from the bottom-right corner over a diagonal tint
/// (`radial-gradient(120% 120% at 100% 100%, c .35, transparent 55%), linear-gradient(135deg, c .2, c .05)`).
struct GlowPanel: ViewModifier {
    let color: Color
    var radial = 0.35, from = 0.2, to = 0.05
    var radius: CGFloat = 24
    var border: Double = 0.35
    var ring = false
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LinearGradient(colors: [color.opacity(from), color.opacity(to)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    RadialGradient(colors: [color.opacity(radial), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 230)
                }.clipShape(RoundedRectangle(cornerRadius: radius))
            )
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(color.opacity(ring ? 1 : border), lineWidth: ring ? 1.5 : 1))
            .overlay { if ring { RoundedRectangle(cornerRadius: radius).stroke(color.opacity(0.15), lineWidth: 4).padding(-4) } }
    }
}
extension View {
    func glowPanel(_ color: Color, radial: Double = 0.35, from: Double = 0.2, to: Double = 0.05, radius: CGFloat = 24, border: Double = 0.35, ring: Bool = false) -> some View {
        modifier(GlowPanel(color: color, radial: radial, from: from, to: to, radius: radius, border: border, ring: ring))
    }
}
