import Foundation

/// Static product data from core.js / app.js: plans, movement metadata, injuries, focus
/// areas, cues, photos, home sessions. Generated from the web source (see
/// ios/tools/make-catalog.mjs), never typed by hand.
public struct Catalog: Codable, Equatable {
    public var plans: [String: PlanMap]
    public var stdFrac: [String: [String: Double]]
    public var qmap: [String: [String: String]]
    public var rcQ: [String: String]
    public var areas: [String]
    public var patLabel: [String: String]
    public var concept: [String: Concept]
    public var conceptOf: [String: String]
    public var focus: [String: FocusDef]
    public var injuries: [String: InjuryDef]
    public var exp: [String: ExpLevel]
    public var nagDays: Int
    public var plates: [Double]
    public var img: [String: String]
    public var imgNone: [String]
    public var cimg: [String: String]
    public var cue: [String: String]
    public var home: [String: HomePlan]
    public var skipWhy: [[String]]
    public var cardioActs: [String: CardioActivityDef]
    public var gridActs: [String]
    public var zname: [String]
    public var zcol: [String]
    public var wcfg: WorkoutConfig
    public var slotName: [String: String]
    public var ctype: [String: String]
    public var heart: [String]
    public var injShow: [[String]]
    public var wdShort: [String: String]
    public var wdLong: [String: String]
    public var wdOrder: [Int]
    public var conceptOrder: [String]
    public var focusOrder: [String]
    public var injuryOrder: [String]

    public static let shared: Catalog = {
        do { return try JSONDecoder().decode(Catalog.self, from: Data(CatalogSource.json.utf8)) }
        catch { fatalError("Catalog.generated.swift does not decode: \(error)") }
    }()

    public static let emptyMeta = Concept(p: [], s: [], pat: "", load: [], alts: [])

    /// `EX_INDEX`: every exercise definition the app knows about, first definition wins.
    public let exIndex: [String: Ex]

    enum CodingKeys: String, CodingKey {
        case plans, stdFrac, qmap, rcQ, areas, patLabel, concept, conceptOf, focus, injuries, exp, nagDays, plates
        case img, imgNone, cimg, cue, home, skipWhy, cardioActs, gridActs, zname, zcol, wcfg
        case slotName, ctype, heart, injShow, wdShort, wdLong, wdOrder, conceptOrder, focusOrder, injuryOrder
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plans = try c.decode([String: PlanMap].self, forKey: .plans)
        stdFrac = try c.decode([String: [String: Double]].self, forKey: .stdFrac)
        qmap = try c.decode([String: [String: String]].self, forKey: .qmap)
        rcQ = try c.decode([String: String].self, forKey: .rcQ)
        areas = try c.decode([String].self, forKey: .areas)
        patLabel = try c.decode([String: String].self, forKey: .patLabel)
        concept = try c.decode([String: Concept].self, forKey: .concept)
        conceptOf = try c.decode([String: String].self, forKey: .conceptOf)
        focus = try c.decode([String: FocusDef].self, forKey: .focus)
        injuries = try c.decode([String: InjuryDef].self, forKey: .injuries)
        exp = try c.decode([String: ExpLevel].self, forKey: .exp)
        nagDays = try c.decode(Int.self, forKey: .nagDays)
        plates = try c.decode([Double].self, forKey: .plates)
        img = try c.decode([String: String].self, forKey: .img)
        imgNone = try c.decode([String].self, forKey: .imgNone)
        cimg = try c.decode([String: String].self, forKey: .cimg)
        cue = try c.decode([String: String].self, forKey: .cue)
        home = try c.decode([String: HomePlan].self, forKey: .home)
        skipWhy = try c.decode([[String]].self, forKey: .skipWhy)
        cardioActs = try c.decode([String: CardioActivityDef].self, forKey: .cardioActs)
        gridActs = try c.decode([String].self, forKey: .gridActs)
        zname = try c.decode([String].self, forKey: .zname)
        zcol = try c.decode([String].self, forKey: .zcol)
        wcfg = try c.decode(WorkoutConfig.self, forKey: .wcfg)
        slotName = try c.decode([String: String].self, forKey: .slotName)
        ctype = try c.decode([String: String].self, forKey: .ctype)
        heart = try c.decode([String].self, forKey: .heart)
        injShow = try c.decode([[String]].self, forKey: .injShow)
        wdShort = try c.decode([String: String].self, forKey: .wdShort)
        wdLong = try c.decode([String: String].self, forKey: .wdLong)
        wdOrder = try c.decode([Int].self, forKey: .wdOrder)
        conceptOrder = try c.decode([String].self, forKey: .conceptOrder)
        focusOrder = try c.decode([String].self, forKey: .focusOrder)
        injuryOrder = try c.decode([String].self, forKey: .injuryOrder)

        var index: [String: Ex] = [:]
        func add(_ x: Ex) { if index[x.id] == nil { index[x.id] = x } }
        for key in ["nr", "nr3", "sa", "sa3"] {
            let p = plans[key] ?? [:]
            for d in p.keys.sorted() { for b in p[d]!.blocks { b.items.forEach(add) } }
        }
        for k in conceptOrder { concept[k]?.alts.forEach(add) }
        for k in focusOrder { focus[k]?.add.forEach { add($0.ex) } }
        for k in injuryOrder { injuries[k]?.subs.forEach { add($0.ex) } }
        exIndex = index
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(plans, forKey: .plans); try c.encode(stdFrac, forKey: .stdFrac); try c.encode(qmap, forKey: .qmap)
        try c.encode(rcQ, forKey: .rcQ); try c.encode(areas, forKey: .areas); try c.encode(patLabel, forKey: .patLabel)
        try c.encode(concept, forKey: .concept); try c.encode(conceptOf, forKey: .conceptOf)
        try c.encode(focus, forKey: .focus); try c.encode(injuries, forKey: .injuries); try c.encode(exp, forKey: .exp)
        try c.encode(nagDays, forKey: .nagDays); try c.encode(plates, forKey: .plates)
        try c.encode(img, forKey: .img); try c.encode(imgNone, forKey: .imgNone); try c.encode(cimg, forKey: .cimg)
        try c.encode(cue, forKey: .cue); try c.encode(home, forKey: .home); try c.encode(skipWhy, forKey: .skipWhy)
        try c.encode(cardioActs, forKey: .cardioActs); try c.encode(gridActs, forKey: .gridActs)
        try c.encode(zname, forKey: .zname); try c.encode(zcol, forKey: .zcol); try c.encode(wcfg, forKey: .wcfg)
        try c.encode(slotName, forKey: .slotName); try c.encode(ctype, forKey: .ctype); try c.encode(heart, forKey: .heart)
        try c.encode(injShow, forKey: .injShow); try c.encode(wdShort, forKey: .wdShort); try c.encode(wdLong, forKey: .wdLong)
        try c.encode(wdOrder, forKey: .wdOrder); try c.encode(conceptOrder, forKey: .conceptOrder)
        try c.encode(focusOrder, forKey: .focusOrder); try c.encode(injuryOrder, forKey: .injuryOrder)
    }

    // MARK: lookups (core.js metaOf / conceptKey / exById pieces)

    /// `metaOf(id)`: the concept that owns the id, directly or as an alternate.
    public func meta(of id: String) -> Concept {
        if let c = conceptOf[id], let m = concept[c] { return m }
        for k in conceptOrder { if let m = concept[k], m.alts.contains(where: { $0.id == id }) { return m } }
        return Catalog.emptyMeta
    }

    /// app.js `conceptKey(id)`.
    public func conceptKey(_ id: String) -> String? {
        if let c = conceptOf[id] { return c }
        return conceptOrder.first { concept[$0]?.alts.contains(where: { $0.id == id }) == true }
    }

    /// app.js `imgOf(id)`: `img/<name>.jpg`, or nil when there is no photo.
    public func imageName(of id: String) -> String? {
        if img[id] != nil { return "img/\(img[id]!).jpg" }
        if imgNone.contains(id) { return nil }
        if let k = conceptKey(id), let s = cimg[k] { return "img/\(s).jpg" }
        return nil
    }

    /// app.js `cueOf(id)`.
    public func cue(of id: String) -> String {
        if let k = conceptKey(id), let c = cue[k] { return c }
        return "Controlled reps, stop 1–2 reps before failure."
    }
}
