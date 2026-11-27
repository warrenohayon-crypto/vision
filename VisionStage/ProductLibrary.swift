//
//  ProductLibrary.swift
//  VisionStage
//
//  The production-element catalog. Dimensions, weights and power figures are
//  approximate planning values — always check the manufacturer's spec sheet
//  before rigging or load calculations.
//

import Foundation

enum ProductLibrary {
    static let all: [LibraryProduct] = buildCatalog()

    private static let byID: [String: LibraryProduct] =
        Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    static func product(id: String) -> LibraryProduct? { byID[id] }

    static func brands(in category: LibraryCategory?) -> [String] {
        let items = category.map { c in all.filter { $0.category == c } } ?? all
        return Array(Set(items.map(\.brand))).sorted()
    }

    static func count(in category: LibraryCategory) -> Int {
        all.filter { $0.category == category }.count
    }
}

// MARK: - Catalog builder

private struct CatalogBuilder {
    var items: [LibraryProduct] = []

    static func slug(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let mapped = folded.map { $0.isLetter || $0.isNumber ? $0 : "-" }
        return String(mapped).split(separator: "-").joined(separator: "-")
    }

    mutating func add(_ brand: String, _ model: String, _ category: LibraryCategory, _ family: String,
                      _ shape: ProductShape, _ w: Float, _ h: Float, _ d: Float,
                      kg: Float = 0, W: Int = 0, _ specs: String = "") {
        items.append(LibraryProduct(
            id: Self.slug("\(brand) \(model)"), brand: brand, model: model,
            category: category, family: family, shape: shape,
            width: w, height: h, depth: d, weight: kg, power: W, specs: specs))
    }

    // Short-hands per category
    mutating func light(_ b: String, _ m: String, _ f: String, _ s: ProductShape,
                        _ w: Float, _ h: Float, _ d: Float, kg: Float = 0, W: Int = 0, _ sp: String = "") {
        add(b, m, .lighting, f, s, w, h, d, kg: kg, W: W, sp)
    }
    mutating func sound(_ b: String, _ m: String, _ f: String, _ s: ProductShape,
                        _ w: Float, _ h: Float, _ d: Float, kg: Float = 0, W: Int = 0, _ sp: String = "") {
        add(b, m, .audio, f, s, w, h, d, kg: kg, W: W, sp)
    }
    mutating func video(_ b: String, _ m: String, _ f: String, _ s: ProductShape,
                        _ w: Float, _ h: Float, _ d: Float, kg: Float = 0, W: Int = 0, _ sp: String = "") {
        add(b, m, .video, f, s, w, h, d, kg: kg, W: W, sp)
    }
}

private func buildCatalog() -> [LibraryProduct] {
    var c = CatalogBuilder()
    addLighting(&c)
    addAudio(&c)
    addVideo(&c)
    addTruss(&c)
    addRigging(&c)
    addStaging(&c)
    addSFX(&c)
    addControl(&c)
    addPower(&c)
    addBackline(&c)
    addVenue(&c)
    return c.items
}

// MARK: - Lighting

private func addLighting(_ c: inout CatalogBuilder) {
    let spot = "Spot / Beam / Profile", wash = "Wash", hybrid = "Hybride",
        beam = "Beam", bar = "Barres & Battens", strobe = "Strobes",
        blind = "Blinders", conv = "Traditionnel", follow = "Poursuites",
        fx = "Effets & Pixels", atmo = "Laser & Atmosphère", par = "PAR LED"

    // Robe
    c.light("Robe", "MegaPointe", hybrid, .movingHead, 0.41, 0.68, 0.25, kg: 22, W: 670, "Lampe 470W, beam/spot/wash, 1.8°–42°")
    c.light("Robe", "Pointe", hybrid, .movingHead, 0.38, 0.59, 0.24, kg: 15, W: 470, "Lampe 280W, beam/spot/wash")
    c.light("Robe", "iPointe", hybrid, .movingHead, 0.41, 0.70, 0.27, kg: 25, W: 600, "IP65, version extérieure du Pointe")
    c.light("Robe", "BMFL Spot", spot, .movingHead, 0.48, 0.79, 0.31, kg: 36, W: 1700, "Lampe 1700W, 5°–55°")
    c.light("Robe", "BMFL Blade", spot, .movingHead, 0.48, 0.79, 0.31, kg: 38, W: 1700, "Couteaux de découpe, 1700W")
    c.light("Robe", "BMFL WashBeam", wash, .movingHeadWash, 0.48, 0.79, 0.31, kg: 36, W: 1700, "Wash/beam 1700W, 3.5°–55°")
    c.light("Robe", "FORTE", spot, .movingHead, 0.47, 0.80, 0.32, kg: 37, W: 1400, "LED 1000W TE, couteaux")
    c.light("Robe", "FORTE FS", follow, .movingHead, 0.47, 0.80, 0.32, kg: 38, W: 1400, "Poursuite RoboSpot, LED 1000W")
    c.light("Robe", "iFORTE", spot, .movingHead, 0.50, 0.83, 0.35, kg: 45, W: 1450, "IP65, LED 1000W")
    c.light("Robe", "iFORTE LTX", spot, .movingHead, 0.52, 0.90, 0.36, kg: 52, W: 1500, "IP65 longue portée 1.2°–30°")
    c.light("Robe", "ESPRITE", spot, .movingHead, 0.43, 0.72, 0.28, kg: 28, W: 850, "LED 650W TE, couteaux")
    c.light("Robe", "iESPRITE", spot, .movingHead, 0.45, 0.75, 0.30, kg: 33, W: 900, "IP65, LED 650W")
    c.light("Robe", "PAINTE", spot, .movingHead, 0.37, 0.62, 0.24, kg: 20, W: 500, "Compact LED 300W, couteaux")
    c.light("Robe", "T1 Profile", spot, .movingHead, 0.45, 0.74, 0.29, kg: 33, W: 850, "Théâtre, MSL multispectral")
    c.light("Robe", "T2 Profile", spot, .movingHead, 0.47, 0.78, 0.30, kg: 36, W: 1000, "Théâtre MSL 850W")
    c.light("Robe", "T11 Profile", conv, .profileSpot, 0.24, 0.40, 0.70, kg: 11, W: 350, "Découpe fixe LED multispectrale")
    c.light("Robe", "T15 Fresnel", conv, .fresnel, 0.34, 0.40, 0.40, kg: 12, W: 450, "Fresnel LED")
    c.light("Robe", "Spiider", wash, .movingHeadWash, 0.42, 0.53, 0.25, kg: 18, W: 690, "Wash 18×40W + flower effect")
    c.light("Robe", "LEDBeam 150", wash, .movingHeadWash, 0.20, 0.32, 0.17, kg: 6, W: 180, "Mini wash/beam 7×40W")
    c.light("Robe", "LEDBeam 350", wash, .movingHeadWash, 0.28, 0.43, 0.22, kg: 11, W: 500, "19×40W, zoom 3.8°–60°")
    c.light("Robe", "LEDWash 300+", wash, .movingHeadWash, 0.31, 0.43, 0.22, kg: 10, W: 400, "Wash 37×15W")
    c.light("Robe", "LEDWash 600+", wash, .movingHeadWash, 0.40, 0.51, 0.26, kg: 16, W: 600, "Wash 37×15W RGBW")
    c.light("Robe", "LEDWash 800", wash, .movingHeadWash, 0.44, 0.57, 0.28, kg: 20, W: 800, "Wash 37×15W, zoom")
    c.light("Robe", "Robin 1200 LEDWash", wash, .movingHeadWash, 0.46, 0.60, 0.30, kg: 24, W: 1000, "Wash 61 LEDs")
    c.light("Robe", "Robin 800X LEDWash", wash, .movingHeadWash, 0.44, 0.56, 0.28, kg: 19, W: 750, "Wash 37 LEDs")
    c.light("Robe", "Tetra2", bar, .movingBar, 1.00, 0.24, 0.13, kg: 18, W: 450, "Barre motorisée 18×40W, tilt")
    c.light("Robe", "Tetra1", bar, .movingBar, 1.00, 0.20, 0.10, kg: 12, W: 250, "Barre motorisée 18 LEDs")
    c.light("Robe", "Tarrantula", wash, .movingHeadWash, 0.45, 0.57, 0.30, kg: 26, W: 1350, "Wash 1 lentille 61×40W")
    c.light("Robe", "SuperSpikie", fx, .movingHeadWash, 0.28, 0.40, 0.20, kg: 9, W: 230, "Beam/flower rotation infinie")
    c.light("Robe", "Spikie", fx, .movingHeadWash, 0.25, 0.37, 0.18, kg: 7, W: 170, "Beam RGBW, flower")
    c.light("Robe", "iBolt", strobe, .movingHead, 0.46, 0.76, 0.32, kg: 37, W: 1200, "Super-beam IP65 0.4°")
    c.light("Robe", "CycFX 8", bar, .movingBar, 0.60, 0.17, 0.10, kg: 7, W: 200, "Barre 8 LEDs, zoom")
    c.light("Robe", "SVOPATT", fx, .movingHeadWash, 0.48, 0.48, 0.48, kg: 30, W: 500, "Effet vintage rotatif")
    c.light("Robe", "Cyclone", fx, .movingHeadWash, 0.38, 0.38, 0.30, kg: 18, W: 400, "Ventilateur + LED")
    c.light("Robe", "DL4S Profile", spot, .movingHead, 0.44, 0.73, 0.29, kg: 32, W: 800, "Théâtre/TV LED 500W")
    c.light("Robe", "Viva CMY", spot, .movingHead, 0.37, 0.58, 0.24, kg: 20, W: 400, "Spot LED 300W CMY")
    c.light("Robe", "RoboSpot BaseStation", follow, .lightingConsole, 0.60, 0.50, 0.40, kg: 15, W: 100, "Poste de pilotage poursuite déportée")

    // Martin (Harman)
    c.light("Martin", "MAC Aura XB", wash, .movingHeadWash, 0.29, 0.42, 0.20, kg: 7, W: 470, "Wash 19 LEDs + aura backlight")
    c.light("Martin", "MAC Aura PXL", wash, .movingHeadWash, 0.32, 0.45, 0.22, kg: 9, W: 600, "Wash pixel-mappable")
    c.light("Martin", "MAC Viper Profile", spot, .movingHead, 0.50, 0.76, 0.32, kg: 38, W: 1400, "Lampe 1000W, couteaux")
    c.light("Martin", "MAC Viper Performance", spot, .movingHead, 0.50, 0.76, 0.32, kg: 40, W: 1400, "Lampe 1000W, framing")
    c.light("Martin", "MAC Encore Performance", spot, .movingHead, 0.44, 0.72, 0.28, kg: 30, W: 900, "LED théâtre WRM/CLD")
    c.light("Martin", "MAC Ultra Performance", spot, .movingHead, 0.53, 0.86, 0.34, kg: 47, W: 1700, "LED 1150W, 46 000 lm")
    c.light("Martin", "MAC Ultra Wash", wash, .movingHeadWash, 0.53, 0.86, 0.34, kg: 45, W: 1700, "Wash LED 1150W")
    c.light("Martin", "MAC Quantum Wash", wash, .movingHeadWash, 0.44, 0.60, 0.29, kg: 22, W: 900, "Wash 37 LEDs")
    c.light("Martin", "MAC Allure Profile", spot, .movingHead, 0.39, 0.63, 0.25, kg: 21, W: 500, "Profile LED compact")
    c.light("Martin", "MAC One", fx, .movingHeadWash, 0.20, 0.33, 0.20, kg: 6, W: 150, "Beam LED compact")
    c.light("Martin", "MAC Axiom Hybrid", hybrid, .movingHead, 0.33, 0.52, 0.24, kg: 15, W: 350, "Hybride compact")
    c.light("Martin", "ERA 300 Profile", spot, .movingHead, 0.36, 0.58, 0.24, kg: 18, W: 350, "Profile LED économique")
    c.light("Martin", "ERA 400 Performance", spot, .movingHead, 0.39, 0.63, 0.25, kg: 22, W: 500, "Profile framing")
    c.light("Martin", "ERA 600 Performance", spot, .movingHead, 0.43, 0.70, 0.28, kg: 28, W: 700, "Profile framing LED")
    c.light("Martin", "ERA 800 Performance", spot, .movingHead, 0.46, 0.76, 0.30, kg: 34, W: 1000, "Profile framing LED")
    c.light("Martin", "Atomic 3000", strobe, .strobe, 0.47, 0.23, 0.26, kg: 6, W: 3000, "Strobe xénon 3000W")
    c.light("Martin", "Atomic 3000 LED", strobe, .strobe, 0.47, 0.25, 0.26, kg: 9, W: 1400, "Strobe LED + aura")
    c.light("Martin", "VDO Sceptron 10", bar, .tube, 1.00, 0.06, 0.06, kg: 2, W: 50, "Tube LED pixel 1m")
    c.light("Martin", "ELP CL", conv, .profileSpot, 0.24, 0.40, 0.70, kg: 10, W: 250, "Découpe LED")
    c.light("Martin", "Rush MH 7 Hybrid", hybrid, .movingHead, 0.36, 0.56, 0.24, kg: 18, W: 350, "Hybride économique")

    // Clay Paky
    c.light("Clay Paky", "Sharpy", beam, .movingHead, 0.30, 0.55, 0.25, kg: 18, W: 470, "Beam 189W, 0°–3.8°")
    c.light("Clay Paky", "Sharpy Plus", hybrid, .movingHead, 0.34, 0.60, 0.26, kg: 22, W: 550, "Beam/spot 330W")
    c.light("Clay Paky", "Sharpy X Frame", hybrid, .movingHead, 0.38, 0.68, 0.28, kg: 27, W: 750, "Hybride avec couteaux")
    c.light("Clay Paky", "Mythos 2", hybrid, .movingHead, 0.39, 0.66, 0.27, kg: 25, W: 600, "Beam/spot 470W")
    c.light("Clay Paky", "Scenius Unico", spot, .movingHead, 0.48, 0.80, 0.32, kg: 42, W: 1700, "Profile 1400W")
    c.light("Clay Paky", "Axcor Profile 900", spot, .movingHead, 0.44, 0.75, 0.29, kg: 35, W: 1200, "Profile LED 850W")
    c.light("Clay Paky", "Xtylos", beam, .movingHead, 0.36, 0.60, 0.26, kg: 25, W: 650, "Beam laser RGB")
    c.light("Clay Paky", "Skylos", beam, .movingHead, 0.60, 0.90, 0.45, kg: 70, W: 4500, "Searchlight extérieur")
    c.light("Clay Paky", "B-EYE K10", wash, .movingHeadWash, 0.38, 0.47, 0.25, kg: 15, W: 750, "Wash 37 LEDs, effets")
    c.light("Clay Paky", "B-EYE K25", wash, .movingHeadWash, 0.48, 0.58, 0.30, kg: 27, W: 1400, "Wash 61 LEDs")
    c.light("Clay Paky", "A.leda K20", wash, .movingHeadWash, 0.42, 0.54, 0.27, kg: 20, W: 900, "Wash 19 LEDs")
    c.light("Clay Paky", "Volero Wave", bar, .movingBar, 1.00, 0.20, 0.12, kg: 16, W: 450, "Barre motorisée")
    c.light("Clay Paky", "Tambora Batten", bar, .ledBatten, 1.00, 0.12, 0.13, kg: 9, W: 300, "Batten LED")
    c.light("Clay Paky", "Stormy CC", strobe, .strobe, 0.48, 0.22, 0.25, kg: 9, W: 1200, "Strobe LED couleur")
    c.light("Clay Paky", "Arolla Profile HP", spot, .movingHead, 0.49, 0.83, 0.33, kg: 46, W: 1500, "Profile LED 900W")

    // Ayrton
    c.light("Ayrton", "Perseo Profile", spot, .movingHead, 0.47, 0.79, 0.31, kg: 38, W: 1200, "IP65 profile LED 750W")
    c.light("Ayrton", "Khamsin", spot, .movingHead, 0.49, 0.80, 0.32, kg: 42, W: 1200, "Profile LED 750W, 6.5°–60°")
    c.light("Ayrton", "Diablo", spot, .movingHead, 0.32, 0.54, 0.23, kg: 17, W: 450, "Profile compact 300W")
    c.light("Ayrton", "Ghibli", spot, .movingHead, 0.42, 0.70, 0.28, kg: 30, W: 750, "Spot LED 500W")
    c.light("Ayrton", "Domino Profile", spot, .movingHead, 0.47, 0.80, 0.32, kg: 41, W: 1300, "IP65 profile 1000W")
    c.light("Ayrton", "Karif LT", beam, .movingHead, 0.30, 0.48, 0.22, kg: 15, W: 300, "Beam LED")
    c.light("Ayrton", "Huracan Profile", spot, .movingHead, 0.53, 0.88, 0.35, kg: 50, W: 1700, "Profile LED 1000W 54 000 lm")
    c.light("Ayrton", "Rivale Profile", spot, .movingHead, 0.38, 0.62, 0.26, kg: 25, W: 650, "IP65 compact")
    c.light("Ayrton", "Mistral", spot, .movingHead, 0.33, 0.54, 0.23, kg: 18, W: 400, "Spot compact")
    c.light("Ayrton", "Eurus Profile", spot, .movingHead, 0.38, 0.64, 0.26, kg: 26, W: 650, "Profile IP65")
    c.light("Ayrton", "Zonda 9 FX", wash, .movingHeadWash, 0.40, 0.52, 0.30, kg: 22, W: 1000, "Wash pixel 7×7 LEDs")
    c.light("Ayrton", "Cobra", beam, .movingHead, 0.42, 0.65, 0.30, kg: 32, W: 900, "Beam laser source IP65")
    c.light("Ayrton", "Argo 6 FX", wash, .movingHeadWash, 0.40, 0.50, 0.30, kg: 20, W: 600, "Wash IP65 pixel")
    c.light("Ayrton", "MagicPanel FX", fx, .panel, 0.40, 0.40, 0.25, kg: 14, W: 500, "Matrice 5×5, rotation infinie")
    c.light("Ayrton", "MagicBlade FX", bar, .movingBar, 0.70, 0.20, 0.12, kg: 10, W: 300, "Barre 7 LEDs rotation infinie")

    // GLP
    c.light("GLP", "impression X4", wash, .movingHeadWash, 0.30, 0.38, 0.20, kg: 8, W: 400, "Wash 19×15W, 7°–50°")
    c.light("GLP", "impression X4 L", wash, .movingHeadWash, 0.42, 0.50, 0.28, kg: 18, W: 900, "Wash 37×15W")
    c.light("GLP", "impression X4 S", wash, .movingHeadWash, 0.23, 0.30, 0.17, kg: 5, W: 170, "Mini wash 7×15W")
    c.light("GLP", "impression X4 Bar 10", bar, .movingBar, 0.50, 0.16, 0.13, kg: 6, W: 180, "Barre 10 LEDs, zoom")
    c.light("GLP", "impression X4 Bar 20", bar, .movingBar, 1.00, 0.16, 0.13, kg: 11, W: 360, "Barre 20 LEDs, zoom")
    c.light("GLP", "impression X5", wash, .movingHeadWash, 0.33, 0.44, 0.22, kg: 12, W: 600, "Wash RGBL 19 LEDs")
    c.light("GLP", "JDC1", strobe, .strobe, 0.54, 0.30, 0.24, kg: 14, W: 1500, "Strobe hybride motorisé")
    c.light("GLP", "JDC Line 1000", strobe, .ledBatten, 1.00, 0.12, 0.10, kg: 9, W: 750, "Strobe linéaire 1m")
    c.light("GLP", "FUSION Stick 20", bar, .ledBatten, 1.00, 0.10, 0.10, kg: 7, W: 300, "Batten RGBW")
    c.light("GLP", "KNV Cube", fx, .panel, 0.30, 0.30, 0.30, kg: 10, W: 400, "Cube strobe pixel modulaire")
    c.light("GLP", "impression S350", spot, .movingHead, 0.35, 0.57, 0.24, kg: 18, W: 350, "Spot LED théâtre")

    // Chauvet Professional
    c.light("Chauvet Professional", "Maverick MK3 Spot", spot, .movingHead, 0.44, 0.73, 0.29, kg: 32, W: 900, "Spot LED 820W")
    c.light("Chauvet Professional", "Maverick MK3 Profile", spot, .movingHead, 0.44, 0.73, 0.29, kg: 34, W: 900, "Profile framing")
    c.light("Chauvet Professional", "Maverick MK3 Wash", wash, .movingHeadWash, 0.43, 0.57, 0.28, kg: 22, W: 900, "Wash 27×40W")
    c.light("Chauvet Professional", "Maverick Force 1 Spot", spot, .movingHead, 0.46, 0.76, 0.30, kg: 36, W: 1000, "Spot LED 1000W")
    c.light("Chauvet Professional", "Maverick Force S Profile", spot, .movingHead, 0.41, 0.69, 0.27, kg: 28, W: 600, "Profile LED")
    c.light("Chauvet Professional", "Maverick Storm 1 Wash", wash, .movingHeadWash, 0.42, 0.55, 0.28, kg: 25, W: 800, "Wash IP65")
    c.light("Chauvet Professional", "Rogue R2 Wash", wash, .movingHeadWash, 0.33, 0.44, 0.22, kg: 11, W: 350, "Wash 19×15W")
    c.light("Chauvet Professional", "Rogue R2 Spot", spot, .movingHead, 0.33, 0.52, 0.23, kg: 17, W: 300, "Spot LED 240W")
    c.light("Chauvet Professional", "Rogue R2 Beam", beam, .movingHead, 0.30, 0.50, 0.22, kg: 16, W: 300, "Beam 2.5°")
    c.light("Chauvet Professional", "Rogue Outcast 2 Beam", beam, .movingHead, 0.32, 0.52, 0.24, kg: 20, W: 350, "Beam IP65")
    c.light("Chauvet Professional", "Color STRIKE M", strobe, .strobe, 0.52, 0.20, 0.20, kg: 11, W: 1000, "Strobe/wash motorisé")
    c.light("Chauvet Professional", "STRIKE Array 4", blind, .blinder, 0.62, 0.22, 0.13, kg: 9, W: 400, "Blinder 4 cellules")
    c.light("Chauvet Professional", "STRIKE Array 2", blind, .blinder, 0.33, 0.22, 0.13, kg: 5, W: 200, "Blinder 2 cellules")
    c.light("Chauvet Professional", "Ovation Reve E-3", conv, .profileSpot, 0.24, 0.40, 0.65, kg: 11, W: 300, "Découpe LED")
    c.light("Chauvet Professional", "WELL Fit", par, .ledPar, 0.15, 0.20, 0.15, kg: 2, W: 40, "PAR batterie sans fil")
    c.light("Chauvet Professional", "COLORado 1 Solo", par, .ledPar, 0.25, 0.30, 0.20, kg: 6, W: 140, "PAR IP65 zoom")
    c.light("Chauvet Professional", "COLORado 3 Solo", par, .ledPar, 0.30, 0.36, 0.25, kg: 10, W: 400, "PAR IP65 zoom")
    c.light("Chauvet Professional", "COLORado PXL Bar 16", bar, .ledBatten, 1.00, 0.18, 0.14, kg: 11, W: 600, "Batten pixel IP65")

    // Elation
    c.light("Elation", "Proteus Maximus", spot, .movingHead, 0.52, 0.86, 0.34, kg: 48, W: 1300, "IP65 profile 1000W")
    c.light("Elation", "Proteus Rayzor 760", wash, .movingHeadWash, 0.42, 0.53, 0.28, kg: 22, W: 700, "Wash IP65 19×40W")
    c.light("Elation", "Proteus Lucius", spot, .movingHead, 0.46, 0.76, 0.30, kg: 38, W: 800, "IP65 profile 600W")
    c.light("Elation", "Proteus Hybrid", hybrid, .movingHead, 0.45, 0.75, 0.30, kg: 38, W: 600, "IP65 hybride")
    c.light("Elation", "Artiste Monet", spot, .movingHead, 0.50, 0.80, 0.32, kg: 42, W: 1100, "Profile LED 950W")
    c.light("Elation", "Artiste Mondrian", spot, .movingHead, 0.50, 0.82, 0.32, kg: 44, W: 1200, "Profile framing 800W")
    c.light("Elation", "Fuze Profile", spot, .movingHead, 0.40, 0.66, 0.27, kg: 25, W: 500, "Profile LED 380W")
    c.light("Elation", "DARTZ 360", beam, .movingHead, 0.30, 0.48, 0.22, kg: 14, W: 250, "Beam rotation infinie")
    c.light("Elation", "Smarty Hybrid", hybrid, .movingHead, 0.34, 0.56, 0.24, kg: 19, W: 400, "Hybride 280W")
    c.light("Elation", "SixBar 1000", bar, .ledBatten, 1.00, 0.10, 0.10, kg: 6, W: 200, "Batten RGBAW+UV")
    c.light("Elation", "Paladin", strobe, .strobe, 0.55, 0.25, 0.22, kg: 15, W: 1500, "Strobe/blinder IP65")
    c.light("Elation", "Chorus Line 16", bar, .movingBar, 1.00, 0.20, 0.12, kg: 15, W: 500, "Barre motorisée 16 LEDs")

    // Vari-Lite / High End / ETC / Astera / others
    c.light("Vari-Lite", "VL2600 Profile", spot, .movingHead, 0.42, 0.70, 0.28, kg: 28, W: 700, "Profile LED")
    c.light("Vari-Lite", "VL3600 Profile", spot, .movingHead, 0.48, 0.78, 0.31, kg: 38, W: 1100, "Profile LED")
    c.light("Vari-Lite", "VL5LED Wash", wash, .movingHeadWash, 0.46, 0.58, 0.30, kg: 28, W: 1000, "Wash LED classique")
    c.light("High End Systems", "SolaFrame 3000", spot, .movingHead, 0.50, 0.82, 0.32, kg: 45, W: 1100, "Profile LED 3000")
    c.light("High End Systems", "SolaSpot Pro 2000", spot, .movingHead, 0.46, 0.75, 0.30, kg: 36, W: 900, "Spot LED")
    c.light("ETC", "Source Four 750", conv, .profileSpot, 0.27, 0.45, 0.64, kg: 7, W: 750, "Découpe tungstène 19°/26°/36°/50°")
    c.light("ETC", "Source Four LED Series 3", conv, .profileSpot, 0.27, 0.45, 0.70, kg: 9, W: 200, "Découpe LED Lustr X8")
    c.light("ETC", "Source Four PAR", conv, .parCan, 0.25, 0.30, 0.30, kg: 4, W: 750, "PAR tungstène")
    c.light("ETC", "ColorSource PAR", par, .ledPar, 0.25, 0.28, 0.20, kg: 4, W: 120, "PAR LED RGB-L")
    c.light("ETC", "Desire D60", par, .ledPar, 0.30, 0.30, 0.20, kg: 6, W: 130, "Wash LED")
    c.light("ETC", "fos/4 Fresnel", conv, .fresnel, 0.35, 0.40, 0.45, kg: 12, W: 450, "Fresnel LED")
    c.light("Astera", "AX1 Titan Tube", bar, .tube, 1.03, 0.05, 0.05, kg: 1.4, W: 50, "Tube LED batterie sans fil")
    c.light("Astera", "Helios Tube", bar, .tube, 0.52, 0.05, 0.05, kg: 0.8, W: 30, "Tube LED 50cm")
    c.light("Astera", "AX9 PowerPAR", par, .ledPar, 0.26, 0.30, 0.20, kg: 4, W: 120, "PAR batterie sans fil")
    c.light("Astera", "AX3 LightDrop", par, .ledPar, 0.12, 0.12, 0.10, kg: 0.7, W: 15, "Mini spot batterie")
    c.light("Astera", "HydraPanel", par, .panel, 0.20, 0.20, 0.06, kg: 1, W: 40, "Panneau LED modulaire")
    c.light("SGM", "P-5", strobe, .strobe, 0.40, 0.26, 0.20, kg: 9, W: 800, "Wash/strobe IP66")
    c.light("SGM", "Q-7", strobe, .strobe, 0.55, 0.30, 0.20, kg: 13, W: 1200, "Strobe/blinder IP66")
    c.light("SGM", "G-7 Spot", spot, .movingHead, 0.45, 0.75, 0.30, kg: 36, W: 900, "Spot IP66")
    c.light("ARRI", "SkyPanel S60-C", conv, .panel, 0.65, 0.30, 0.15, kg: 12, W: 450, "Softlight LED TV")
    c.light("ARRI", "Orbiter", conv, .profileSpot, 0.30, 0.40, 0.50, kg: 12, W: 500, "LED directionnel multi-optiques")
    c.light("Robert Juliat", "Cyrano 2500", follow, .followspot, 0.40, 1.40, 1.30, kg: 70, W: 2500, "Poursuite HMI 2500W")
    c.light("Robert Juliat", "Merlin", follow, .followspot, 0.35, 1.30, 1.10, kg: 55, W: 800, "Poursuite LED")
    c.light("Lycian", "M2 Long Throw", follow, .followspot, 0.40, 1.45, 1.40, kg: 75, W: 2500, "Poursuite longue portée")
    c.light("Générique", "PAR 64 1kW", conv, .parCan, 0.25, 0.30, 0.40, kg: 3, W: 1000, "PAR tungstène CP62")
    c.light("Générique", "PAR 56 300W", conv, .parCan, 0.20, 0.25, 0.30, kg: 2, W: 300, "PAR tungstène")
    c.light("Générique", "Fresnel 2kW", conv, .fresnel, 0.35, 0.42, 0.40, kg: 9, W: 2000, "Fresnel tungstène")
    c.light("Générique", "Fresnel 1kW", conv, .fresnel, 0.30, 0.36, 0.34, kg: 6, W: 1000, "Fresnel tungstène")
    c.light("Générique", "Blinder 4-Lite DWE", blind, .blinder, 0.55, 0.22, 0.18, kg: 7, W: 2600, "Molefay 4×650W")
    c.light("Générique", "Blinder 2-Lite DWE", blind, .blinder, 0.30, 0.22, 0.18, kg: 4, W: 1300, "Molefay 2×650W")
    c.light("Générique", "Barre ACL 4×PAR", conv, .ledBatten, 1.00, 0.25, 0.25, kg: 12, W: 1000, "Rampe ACL 4 lampes")
    c.light("Générique", "PAR LED 18×15W RGBWA", par, .ledPar, 0.24, 0.26, 0.15, kg: 4, W: 280, "PAR LED standard")
    c.light("Générique", "Barre LED 12×10W", bar, .ledBatten, 1.00, 0.10, 0.10, kg: 4, W: 150, "Batten LED RGBW")
    c.light("Générique", "Cyclïode 1kW", conv, .ledBatten, 0.25, 0.30, 0.20, kg: 4, W: 1000, "Horiziode / cyclorama")

    // Lasers & atmosphere
    c.light("Kvant", "Spectrum 30", atmo, .laser, 0.40, 0.20, 0.45, kg: 16, W: 900, "Laser RGB 30W")
    c.light("Kvant", "Clubmax 6000", atmo, .laser, 0.30, 0.15, 0.33, kg: 9, W: 300, "Laser RGB 6W")
    c.light("Kvant", "Atom 10", atmo, .laser, 0.30, 0.15, 0.35, kg: 10, W: 400, "Laser RGB 10W")
    c.light("Kvant", "Spectrum 50 FB4", atmo, .laser, 0.45, 0.22, 0.50, kg: 22, W: 1300, "Laser RGB 50W")
    c.light("MDG", "theONE", atmo, .hazer, 0.60, 0.40, 0.30, kg: 30, W: 1500, "Brouillard/haze CO2")
    c.light("MDG", "ATMe", atmo, .hazer, 0.50, 0.35, 0.30, kg: 25, W: 1300, "Hazer CO2")
    c.light("Look Solutions", "Unique 2.1", atmo, .hazer, 0.53, 0.30, 0.25, kg: 14, W: 1500, "Hazer huile")
    c.light("Look Solutions", "Viper NT", atmo, .hazer, 0.60, 0.35, 0.28, kg: 16, W: 2600, "Machine à fumée")
    c.light("Le Maitre", "Neutron XS", atmo, .hazer, 0.40, 0.28, 0.25, kg: 9, W: 800, "Hazer compact")
    c.light("Antari", "HZ-500", atmo, .hazer, 0.42, 0.25, 0.25, kg: 10, W: 700, "Hazer")
    c.light("Antari", "Z-1500 II", atmo, .hazer, 0.48, 0.24, 0.24, kg: 9, W: 1500, "Machine à fumée")
    c.light("Smoke Factory", "Tour Hazer II", atmo, .hazer, 0.55, 0.30, 0.28, kg: 15, W: 1000, "Hazer tournée")
}

// MARK: - Audio

private func addAudio(_ c: inout CatalogBuilder) {
    let la = "Line array", sub = "Subwoofers", ps = "Point source", mon = "Retours / Wedges",
        amp = "Amplification", mic = "Micros", col = "Colonnes"

    // L-Acoustics
    c.sound("L-Acoustics", "K1", la, .lineArrayBox, 1.34, 0.44, 0.56, kg: 106, W: 0, "Grand format 3 voies")
    c.sound("L-Acoustics", "K1-SB", sub, .lineArrayBox, 1.34, 0.44, 0.56, kg: 108, W: 0, "Extension grave accrochée")
    c.sound("L-Acoustics", "K2", la, .lineArrayBox, 1.34, 0.35, 0.50, kg: 56, W: 0, "Line array 3 voies, 70°/110°")
    c.sound("L-Acoustics", "K3", la, .lineArrayBox, 1.10, 0.33, 0.43, kg: 43, W: 0, "Line array 12\"")
    c.sound("L-Acoustics", "Kara II", la, .lineArrayBox, 0.73, 0.25, 0.48, kg: 26, W: 0, "Line array 2×8\"")
    c.sound("L-Acoustics", "Kiva II", la, .lineArrayBox, 0.52, 0.17, 0.39, kg: 14, W: 0, "Line array ultra-compact")
    c.sound("L-Acoustics", "L2", la, .lineArrayBox, 1.34, 1.00, 0.55, kg: 255, W: 0, "Système ligne progressive")
    c.sound("L-Acoustics", "KS28", sub, .subwoofer, 1.34, 0.55, 0.90, kg: 79, W: 0, "Sub 2×18\"")
    c.sound("L-Acoustics", "SB28", sub, .subwoofer, 1.10, 0.55, 0.70, kg: 93, W: 0, "Sub 2×18\"")
    c.sound("L-Acoustics", "KS21", sub, .subwoofer, 0.70, 0.55, 0.73, kg: 49, W: 0, "Sub 21\"")
    c.sound("L-Acoustics", "A15 Focus", ps, .pointSource, 0.73, 0.43, 0.42, kg: 38, W: 0, "Constant curvature")
    c.sound("L-Acoustics", "A10 Wide", ps, .pointSource, 0.55, 0.29, 0.36, kg: 19, W: 0, "Constant curvature compact")
    c.sound("L-Acoustics", "X15 HiQ", mon, .wedge, 0.55, 0.38, 0.55, kg: 21, W: 0, "Retour coaxial 15\"")
    c.sound("L-Acoustics", "X12", mon, .wedge, 0.43, 0.34, 0.45, kg: 20, W: 0, "Retour coaxial 12\"")
    c.sound("L-Acoustics", "X8", ps, .pointSource, 0.25, 0.43, 0.25, kg: 12, W: 0, "Coaxial 8\"")
    c.sound("L-Acoustics", "Syva", col, .columnSpeaker, 0.14, 1.35, 0.24, kg: 22, W: 0, "Colonne design")
    c.sound("L-Acoustics", "LA12X Rack", amp, .ampRack, 0.60, 1.20, 0.80, kg: 180, W: 6000, "Rack 3× LA12X")

    // d&b audiotechnik
    c.sound("d&b audiotechnik", "GSL8", la, .lineArrayBox, 1.30, 0.42, 0.56, kg: 80, W: 0, "Line array cardioïde 80°")
    c.sound("d&b audiotechnik", "GSL12", la, .lineArrayBox, 1.30, 0.42, 0.56, kg: 80, W: 0, "Line array cardioïde 120°")
    c.sound("d&b audiotechnik", "KSL8", la, .lineArrayBox, 1.10, 0.38, 0.48, kg: 64, W: 0, "Line array cardioïde")
    c.sound("d&b audiotechnik", "J8", la, .lineArrayBox, 1.12, 0.37, 0.52, kg: 60, W: 0, "Line array 3 voies")
    c.sound("d&b audiotechnik", "J12", la, .lineArrayBox, 1.12, 0.37, 0.52, kg: 60, W: 0, "Line array 120°")
    c.sound("d&b audiotechnik", "J-SUB", sub, .subwoofer, 1.12, 0.65, 0.73, kg: 113, W: 0, "Sub cardioïde 3×18\"")
    c.sound("d&b audiotechnik", "V8", la, .lineArrayBox, 0.84, 0.32, 0.47, kg: 37, W: 0, "Line array 80°")
    c.sound("d&b audiotechnik", "V12", la, .lineArrayBox, 0.84, 0.32, 0.47, kg: 37, W: 0, "Line array 120°")
    c.sound("d&b audiotechnik", "V-SUB", sub, .subwoofer, 0.84, 0.55, 0.70, kg: 69, W: 0, "Sub cardioïde")
    c.sound("d&b audiotechnik", "Y8", la, .lineArrayBox, 0.53, 0.24, 0.38, kg: 20, W: 0, "Line array compact")
    c.sound("d&b audiotechnik", "Y10P", ps, .pointSource, 0.53, 0.24, 0.38, kg: 20, W: 0, "Point source")
    c.sound("d&b audiotechnik", "SL-SUB", sub, .subwoofer, 1.30, 0.80, 1.00, kg: 195, W: 0, "Sub cardioïde 3×21\"")
    c.sound("d&b audiotechnik", "M4", mon, .wedge, 0.58, 0.37, 0.51, kg: 25, W: 0, "Retour coaxial 15\"")
    c.sound("d&b audiotechnik", "M2", mon, .wedge, 0.71, 0.33, 0.58, kg: 33, W: 0, "Retour 2×12\"")
    c.sound("d&b audiotechnik", "D80 Touring Rack", amp, .ampRack, 0.60, 1.20, 0.80, kg: 170, W: 7000, "Rack 3× D80")

    // Meyer Sound
    c.sound("Meyer Sound", "PANTHER", la, .lineArrayBox, 1.25, 0.36, 0.56, kg: 68, W: 2000, "Line array amplifié")
    c.sound("Meyer Sound", "LEO-M", la, .lineArrayBox, 1.37, 0.51, 0.56, kg: 116, W: 3000, "Line array amplifié grand format")
    c.sound("Meyer Sound", "LYON", la, .lineArrayBox, 1.37, 0.43, 0.56, kg: 91, W: 2500, "Line array amplifié")
    c.sound("Meyer Sound", "LEOPARD", la, .lineArrayBox, 0.92, 0.36, 0.51, kg: 37, W: 1200, "Line array compact amplifié")
    c.sound("Meyer Sound", "LINA", la, .lineArrayBox, 0.72, 0.28, 0.40, kg: 22, W: 800, "Line array très compact")
    c.sound("Meyer Sound", "1100-LFC", sub, .subwoofer, 1.37, 0.55, 0.76, kg: 113, W: 2500, "Sub 2×18\" amplifié")
    c.sound("Meyer Sound", "900-LFC", sub, .subwoofer, 0.92, 0.55, 0.76, kg: 78, W: 1800, "Sub 2×18\" amplifié")
    c.sound("Meyer Sound", "2100-LFC", sub, .subwoofer, 1.37, 0.60, 0.86, kg: 136, W: 3000, "Sub 2×18\" amplifié")
    c.sound("Meyer Sound", "MJF-212A", mon, .wedge, 0.71, 0.36, 0.53, kg: 54, W: 1200, "Retour amplifié 2×12\"")
    c.sound("Meyer Sound", "UPA-1P", ps, .pointSource, 0.55, 0.37, 0.39, kg: 34, W: 600, "Point source amplifié")
    c.sound("Meyer Sound", "ULTRA-X40", ps, .pointSource, 0.33, 0.55, 0.36, kg: 26, W: 600, "Point source compact")

    // JBL / Martin Audio / Adamson / Nexo / Coda / others
    c.sound("JBL", "VTX A12", la, .lineArrayBox, 1.20, 0.35, 0.51, kg: 66, W: 0, "Line array 2×12\"")
    c.sound("JBL", "VTX A8", la, .lineArrayBox, 0.96, 0.26, 0.48, kg: 40, W: 0, "Line array 2×8\"")
    c.sound("JBL", "VTX B28", sub, .subwoofer, 1.20, 0.56, 0.86, kg: 112, W: 0, "Sub 2×18\"")
    c.sound("JBL", "VTX V25-II", la, .lineArrayBox, 1.12, 0.38, 0.55, kg: 82, W: 0, "Line array 2×15\"")
    c.sound("JBL", "SRX835P", ps, .pointSource, 0.55, 1.16, 0.53, kg: 50, W: 2000, "Enceinte amplifiée 3 voies")
    c.sound("JBL", "PRX915", ps, .pointSource, 0.44, 0.71, 0.37, kg: 22, W: 2000, "Enceinte amplifiée 15\"")
    c.sound("Martin Audio", "MLA", la, .lineArrayBox, 1.07, 0.38, 0.69, kg: 102, W: 0, "Multicellulaire grand format")
    c.sound("Martin Audio", "WPL", la, .lineArrayBox, 1.10, 0.38, 0.62, kg: 75, W: 0, "Wavefront Precision Longbow")
    c.sound("Martin Audio", "WPM", la, .lineArrayBox, 0.54, 0.18, 0.42, kg: 18, W: 0, "Wavefront Precision Mini")
    c.sound("Martin Audio", "SXH218", sub, .subwoofer, 1.10, 0.56, 0.85, kg: 120, W: 0, "Sub 2×18\"")
    c.sound("Adamson", "E15", la, .lineArrayBox, 1.30, 0.42, 0.56, kg: 88, W: 0, "Line array 2×15\"")
    c.sound("Adamson", "E12", la, .lineArrayBox, 1.10, 0.35, 0.53, kg: 61, W: 0, "Line array 2×12\"")
    c.sound("Adamson", "S10", la, .lineArrayBox, 0.74, 0.27, 0.53, kg: 33, W: 0, "Line array 2×10\"")
    c.sound("Adamson", "CS10", la, .lineArrayBox, 0.74, 0.27, 0.53, kg: 34, W: 0, "Line array amplifié")
    c.sound("Adamson", "E219", sub, .subwoofer, 1.30, 0.60, 0.90, kg: 145, W: 0, "Sub 2×19\"")
    c.sound("Nexo", "STM M46", la, .lineArrayBox, 1.08, 0.36, 0.73, kg: 85, W: 0, "Système modulaire")
    c.sound("Nexo", "GEO M12", la, .lineArrayBox, 0.66, 0.28, 0.42, kg: 27, W: 0, "Line array 12\"")
    c.sound("Nexo", "GEO M10", la, .lineArrayBox, 0.56, 0.25, 0.37, kg: 21, W: 0, "Line array 10\"")
    c.sound("Nexo", "RS18", sub, .subwoofer, 0.70, 0.67, 0.80, kg: 87, W: 0, "Sub Ray 18\"")
    c.sound("Nexo", "PS15-R2", mon, .wedge, 0.45, 0.70, 0.40, kg: 34, W: 0, "Enceinte/retour 15\"")
    c.sound("Coda Audio", "AiRAY", la, .lineArrayBox, 1.20, 0.37, 0.53, kg: 76, W: 0, "Line array 2×12\"")
    c.sound("Coda Audio", "ViRAY", la, .lineArrayBox, 0.68, 0.24, 0.40, kg: 21, W: 0, "Line array compact")
    c.sound("Coda Audio", "SCV-F", sub, .subwoofer, 1.20, 0.60, 0.80, kg: 120, W: 0, "Sub cardioïde")
    c.sound("Funktion-One", "Vero V90", la, .lineArrayBox, 1.20, 0.55, 0.75, kg: 120, W: 0, "Système Vero")
    c.sound("Funktion-One", "F221", sub, .subwoofer, 1.10, 0.60, 0.90, kg: 110, W: 0, "Sub 2×21\"")
    c.sound("Bose", "ShowMatch SM10", la, .lineArrayBox, 0.68, 0.29, 0.50, kg: 32, W: 0, "Array DeltaQ")
    c.sound("RCF", "HDL 50-A", la, .lineArrayBox, 1.10, 0.40, 0.56, kg: 68, W: 4400, "Line array amplifié")
    c.sound("RCF", "TT+ 33-A", ps, .pointSource, 0.53, 0.83, 0.52, kg: 40, W: 2000, "Enceinte amplifiée")

    // Microphones & stands
    c.sound("Shure", "SM58 + pied", mic, .microphone, 0.30, 1.60, 0.30, kg: 3, W: 0, "Micro dynamique chant sur pied perche")
    c.sound("Shure", "SM57 + pied", mic, .microphone, 0.30, 1.20, 0.30, kg: 3, W: 0, "Micro instrument sur pied")
    c.sound("Shure", "Beta 91A", mic, .microphone, 0.10, 0.05, 0.10, kg: 0.5, W: 0, "Micro grosse caisse")
    c.sound("Shure", "Axient Digital Rack", amp, .ampRack, 0.60, 0.80, 0.60, kg: 45, W: 400, "Rack HF 8 canaux")
    c.sound("Sennheiser", "Digital 6000 Rack", amp, .ampRack, 0.60, 0.80, 0.60, kg: 40, W: 300, "Rack HF")
    c.sound("Sennheiser", "MD 421 + pied", mic, .microphone, 0.30, 1.10, 0.30, kg: 3, W: 0, "Micro instrument")
    c.sound("Neumann", "KM 184 + pied", mic, .microphone, 0.30, 1.80, 0.30, kg: 3, W: 0, "Micro statique overhead")
    c.sound("Générique", "Pupitre conférence + micro", mic, .microphone, 0.60, 1.20, 0.45, kg: 15, W: 0, "Pupitre orateur")
}

// MARK: - Video

private func addVideo(_ c: inout CatalogBuilder) {
    let led = "Murs LED", proj = "Projecteurs vidéo", cam = "Caméras", screen = "Écrans de projection",
        srv = "Serveurs médias"

    c.video("ROE Visual", "Black Pearl BP2V2 (0.5×0.5)", led, .ledPanel, 0.50, 0.50, 0.08, kg: 9.4, W: 190, "Pitch 2.84 mm")
    c.video("ROE Visual", "Black Onyx BO3 (0.6×0.34)", led, .ledPanel, 0.60, 0.34, 0.08, kg: 6.5, W: 140, "Pitch 3.47 mm, sol/plafond")
    c.video("ROE Visual", "Carbon CB5 (1.2×0.6)", led, .ledPanel, 1.20, 0.60, 0.08, kg: 12, W: 450, "Pitch 5.77 mm, semi-transparent")
    c.video("ROE Visual", "Carbon CB8 (1.2×0.6)", led, .ledPanel, 1.20, 0.60, 0.08, kg: 11, W: 400, "Pitch 8.3 mm")
    c.video("ROE Visual", "Vanish V8T (1×1)", led, .ledPanel, 1.00, 1.00, 0.06, kg: 9, W: 300, "LED transparent")
    c.video("ROE Visual", "Black Marble BM4 (0.5×0.5)", led, .ledPanel, 0.50, 0.50, 0.10, kg: 12, W: 150, "Dalle LED sol")
    c.video("Absen", "PL2.5 Pro (0.5×0.5)", led, .ledPanel, 0.50, 0.50, 0.08, kg: 7.5, W: 170, "Pitch 2.5 mm")
    c.video("Absen", "A27 Plus (0.5×1)", led, .ledPanel, 0.50, 1.00, 0.08, kg: 11, W: 300, "Pitch 2.6 mm")
    c.video("Absen", "Polaris PL3.9 (0.5×1)", led, .ledPanel, 0.50, 1.00, 0.08, kg: 10, W: 300, "Pitch 3.9 mm")
    c.video("Unilumin", "Upad IV 2.6 (0.5×1)", led, .ledPanel, 0.50, 1.00, 0.08, kg: 10, W: 300, "Pitch 2.6 mm")
    c.video("INFiLED", "AR 3.9 (0.5×1)", led, .ledPanel, 0.50, 1.00, 0.08, kg: 11, W: 320, "Pitch 3.9 mm")
    c.video("INFiLED", "ER 2.6 (0.5×0.5)", led, .ledPanel, 0.50, 0.50, 0.08, kg: 7.5, W: 180, "Pitch 2.6 mm")
    c.video("Leyard", "CLI 2.6 (0.5×0.5)", led, .ledPanel, 0.50, 0.50, 0.08, kg: 8, W: 180, "Pitch 2.6 mm")
    c.video("Générique", "Mur LED 6×3.5 m", led, .ledPanel, 6.00, 3.50, 0.10, kg: 700, W: 15000, "Écran LED assemblé 16:9")
    c.video("Générique", "Mur LED 4×2.25 m", led, .ledPanel, 4.00, 2.25, 0.10, kg: 320, W: 7000, "Écran LED assemblé 16:9")
    c.video("Générique", "Mur LED 10×5.6 m", led, .ledPanel, 10.0, 5.60, 0.10, kg: 1800, W: 40000, "Écran LED principal 16:9")
    c.video("Générique", "Écran LED latéral 3×5 m", led, .ledPanel, 3.00, 5.00, 0.10, kg: 450, W: 9000, "IMAG portrait")

    c.video("Barco", "UDX-4K32", proj, .projector, 0.73, 0.32, 0.92, kg: 98, W: 2800, "31 000 lm laser 4K")
    c.video("Barco", "UDX-4K40 FLEX", proj, .projector, 0.73, 0.32, 0.92, kg: 103, W: 3300, "37 500 lm laser 4K")
    c.video("Barco", "UDM-4K22", proj, .projector, 0.62, 0.27, 0.74, kg: 63, W: 1800, "21 000 lm laser")
    c.video("Christie", "Griffyn 4K35-RGB", proj, .projector, 0.76, 0.38, 1.04, kg: 115, W: 3500, "36 500 lm laser RGB")
    c.video("Christie", "Crimson WU31", proj, .projector, 0.67, 0.29, 0.84, kg: 78, W: 2500, "31 500 lm 3DLP")
    c.video("Panasonic", "PT-RQ35K", proj, .projector, 0.76, 0.37, 1.03, kg: 120, W: 3100, "30 500 lm laser 4K")
    c.video("Panasonic", "PT-RZ21K", proj, .projector, 0.62, 0.30, 0.79, kg: 49, W: 1900, "20 000 lm laser")
    c.video("Epson", "EB-PU2220B", proj, .projector, 0.59, 0.25, 0.69, kg: 36, W: 1400, "20 000 lm 3LCD")

    c.video("Sony", "HDC-3500", cam, .camera, 0.40, 1.60, 0.70, kg: 45, W: 150, "Caméra broadcast 4K sur trépied")
    c.video("Sony", "HDC-5500", cam, .camera, 0.40, 1.60, 0.70, kg: 47, W: 160, "Caméra broadcast 4K HDR")
    c.video("Grass Valley", "LDX 100", cam, .camera, 0.40, 1.60, 0.70, kg: 45, W: 150, "Caméra broadcast")
    c.video("Blackmagic", "URSA Broadcast G2", cam, .camera, 0.40, 1.60, 0.70, kg: 30, W: 60, "Caméra broadcast 6K")
    c.video("Panasonic", "AW-UE150 PTZ", cam, .ptzCamera, 0.23, 0.30, 0.23, kg: 5, W: 50, "Caméra robotisée 4K")
    c.video("Sony", "BRC-X400 PTZ", cam, .ptzCamera, 0.20, 0.28, 0.20, kg: 4, W: 40, "Caméra robotisée 4K")
    c.video("Générique", "Grue caméra Jimmy Jib", cam, .camera, 0.60, 2.50, 4.00, kg: 120, W: 100, "Bras de grue télescopique")

    c.video("Fast-Fold", "Écran 16:9 4×2.25 m", screen, .projectionScreen, 4.00, 2.25, 0.05, kg: 45, W: 0, "Toile face/rétro sur cadre")
    c.video("Fast-Fold", "Écran 16:9 6×3.4 m", screen, .projectionScreen, 6.00, 3.40, 0.05, kg: 80, W: 0, "Toile face/rétro sur cadre")
    c.video("Fast-Fold", "Écran 16:9 8×4.5 m", screen, .projectionScreen, 8.00, 4.50, 0.05, kg: 120, W: 0, "Toile face/rétro sur cadre")

    c.video("disguise", "vx 4+", srv, .mediaServer, 0.60, 0.40, 0.70, kg: 30, W: 1200, "Serveur média 4×4K")
    c.video("disguise", "gx 3", srv, .mediaServer, 0.60, 0.40, 0.70, kg: 28, W: 1200, "Serveur média génératif")
    c.video("Resolume", "Arena Media Rack", srv, .mediaServer, 0.60, 0.50, 0.70, kg: 25, W: 800, "Rack VJ")
    c.video("Barco", "E2 Gen 2", srv, .mediaServer, 0.60, 0.40, 0.70, kg: 25, W: 800, "Processeur d'écran")
    c.video("Brompton", "Tessera SX40 Rack", srv, .mediaServer, 0.60, 0.30, 0.60, kg: 15, W: 200, "Processeur LED")
    c.video("Ross Video", "Carbonite Ultra", srv, .mixingConsole, 1.00, 0.30, 0.50, kg: 20, W: 300, "Mélangeur vidéo")
    c.video("Blackmagic", "ATEM Constellation 4K", srv, .mixingConsole, 0.90, 0.25, 0.45, kg: 12, W: 200, "Mélangeur vidéo")
}

// MARK: - Truss (generated by section × length)

private func addTruss(_ c: inout CatalogBuilder) {
    struct Section { let brand: String; let name: String; let shape: ProductShape; let size: Float; let kgPerM: Float; let note: String }
    let sections = [
        Section(brand: "Prolyte", name: "H30V", shape: .boxTruss, size: 0.29, kgPerM: 5.5, note: "Carré 290 mm"),
        Section(brand: "Prolyte", name: "H40V", shape: .boxTruss, size: 0.39, kgPerM: 7.0, note: "Carré 390 mm"),
        Section(brand: "Prolyte", name: "H30D", shape: .triangleTruss, size: 0.29, kgPerM: 4.2, note: "Triangle 290 mm"),
        Section(brand: "Prolyte", name: "X30L", shape: .ladderTruss, size: 0.29, kgPerM: 2.5, note: "Échelle 290 mm"),
        Section(brand: "Prolyte", name: "S52SV", shape: .boxTruss, size: 0.52, kgPerM: 14, note: "Carré 520 mm heavy duty"),
        Section(brand: "Global Truss", name: "F34", shape: .boxTruss, size: 0.29, kgPerM: 5.0, note: "Carré 290 mm"),
        Section(brand: "Global Truss", name: "F44P", shape: .boxTruss, size: 0.40, kgPerM: 7.5, note: "Carré 400 mm"),
        Section(brand: "Global Truss", name: "F33", shape: .triangleTruss, size: 0.29, kgPerM: 3.8, note: "Triangle 290 mm"),
        Section(brand: "Eurotruss", name: "FD34", shape: .boxTruss, size: 0.29, kgPerM: 5.3, note: "Carré 290 mm"),
        Section(brand: "Eurotruss", name: "HD44", shape: .boxTruss, size: 0.40, kgPerM: 8.0, note: "Carré 400 mm"),
        Section(brand: "Tomcat", name: "Medium Duty 12\"×12\"", shape: .boxTruss, size: 0.30, kgPerM: 5.8, note: "Carré 12 pouces"),
        Section(brand: "Tomcat", name: "Spigoted 20.5\"×20.5\"", shape: .boxTruss, size: 0.52, kgPerM: 13, note: "Carré 20.5 pouces"),
        Section(brand: "Milos", name: "M290", shape: .boxTruss, size: 0.29, kgPerM: 5.2, note: "Carré 290 mm"),
        Section(brand: "Litec", name: "QX30SA", shape: .boxTruss, size: 0.29, kgPerM: 5.0, note: "Carré 290 mm"),
    ]
    let lengths: [Float] = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0]
    for s in sections {
        for l in lengths {
            c.add(s.brand, "\(s.name) \(formatMeters(l))", .truss, "Truss \(s.shape == .boxTruss ? "carré" : s.shape == .triangleTruss ? "triangle" : "échelle")",
                  s.shape, l, s.size, s.size, kg: s.kgPerM * l, W: 0, s.note)
        }
        c.add(s.brand, "\(s.name) Corner block", .truss, "Angles & cubes", .cornerBlock, s.size, s.size, s.size, kg: 4, W: 0, "Cube/angle 6 directions")
    }
    // Ready-made spans & ground support
    for l: Float in [6, 8, 10, 12, 14, 16] {
        c.add("Prolyte", "Pont H30V \(formatMeters(l))", .truss, "Ponts assemblés", .boxTruss, l, 0.29, 0.29, kg: 5.5 * l, W: 0, "Pont assemblé")
        c.add("Prolyte", "Pont H40V \(formatMeters(l))", .truss, "Ponts assemblés", .boxTruss, l, 0.39, 0.39, kg: 7 * l, W: 0, "Pont assemblé")
    }
    for h: Float in [4, 6, 8] {
        c.add("Prolyte", "Tour MPT \(formatMeters(h))", .truss, "Ground support", .trussTower, 0.60, h, 0.60, kg: 60 + 12 * h, W: 0, "Tour ground support + sleeve block")
        c.add("Global Truss", "Tower GT \(formatMeters(h))", .truss, "Ground support", .trussTower, 0.60, h, 0.60, kg: 55 + 12 * h, W: 0, "Tour ground support")
    }
    c.add("Prolyte", "Base plate 80×80", .truss, "Ground support", .basePlate, 0.80, 0.02, 0.80, kg: 25, W: 0, "Embase acier")
    c.add("Global Truss", "Base plate 60×60", .truss, "Ground support", .basePlate, 0.60, 0.02, 0.60, kg: 17, W: 0, "Embase acier")
    c.add("Prolyte", "MPT Roof 10×8 m", .truss, "Toits de scène", .roofSystem, 10, 7.5, 8, kg: 2500, W: 0, "Toit ground support H30V/H40V")
    c.add("Prolyte", "ST Roof 14×12 m", .truss, "Toits de scène", .roofSystem, 14, 9, 12, kg: 6000, W: 0, "Toit scène festival")
    c.add("Global Truss", "GT Roof 12×10 m", .truss, "Toits de scène", .roofSystem, 12, 8, 10, kg: 4200, W: 0, "Toit ground support")
    c.add("Stageline", "SL100", .truss, "Scènes mobiles", .mobileStage, 6.1, 6.5, 4.9, kg: 6800, W: 0, "Scène mobile 6×5 m")
    c.add("Stageline", "SL260", .truss, "Scènes mobiles", .mobileStage, 12.2, 9.5, 10.4, kg: 24000, W: 0, "Scène mobile 12×10 m")
    c.add("Stageline", "SAM450", .truss, "Scènes mobiles", .mobileStage, 18.3, 13.5, 12.2, kg: 36000, W: 0, "Scène mobile 18×12 m")
    c.add("Stageline", "SAM575", .truss, "Scènes mobiles", .mobileStage, 20.1, 15.0, 15.2, kg: 45000, W: 0, "Scène mobile 20×15 m")
}

private func formatMeters(_ v: Float) -> String {
    v == v.rounded() ? "\(Int(v)) m" : String(format: "%.1f m", v)
}

// MARK: - Rigging

private func addRigging(_ c: inout CatalogBuilder) {
    let hoist = "Moteurs", acc = "Accessoires", bump = "Bumpers"
    c.add("Columbus McKinnon", "Lodestar 1 t", .rigging, hoist, .chainHoist, 0.30, 0.55, 0.30, kg: 55, W: 1500, "Palan électrique 1000 kg D8")
    c.add("Columbus McKinnon", "Lodestar 500 kg", .rigging, hoist, .chainHoist, 0.28, 0.48, 0.28, kg: 40, W: 1100, "Palan électrique 500 kg")
    c.add("Columbus McKinnon", "Lodestar 2 t", .rigging, hoist, .chainHoist, 0.34, 0.70, 0.34, kg: 85, W: 2200, "Palan électrique 2000 kg")
    c.add("Chainmaster", "D8+ 500 kg", .rigging, hoist, .chainHoist, 0.28, 0.48, 0.28, kg: 40, W: 1100, "Palan D8+")
    c.add("Chainmaster", "D8+ 1000 kg", .rigging, hoist, .chainHoist, 0.30, 0.55, 0.30, kg: 55, W: 1500, "Palan D8+")
    c.add("Chainmaster", "BGV-C1 500 kg", .rigging, hoist, .chainHoist, 0.30, 0.52, 0.30, kg: 45, W: 1100, "Palan au-dessus du public")
    c.add("Liftket", "Star Lift D8+ 1000 kg", .rigging, hoist, .chainHoist, 0.30, 0.55, 0.30, kg: 55, W: 1500, "Palan D8+")
    c.add("Verlinde", "Stagemaker SR10", .rigging, hoist, .chainHoist, 0.30, 0.55, 0.30, kg: 55, W: 1500, "Palan 1000 kg")
    c.add("Kinesys", "Elevation 1+", .rigging, hoist, .chainHoist, 0.32, 0.58, 0.32, kg: 60, W: 1600, "Palan automatisé à vitesse variable")
    c.add("Movecat", "VMK 500", .rigging, hoist, .chainHoist, 0.30, 0.55, 0.30, kg: 50, W: 1500, "Palan variable")
    c.add("L-Acoustics", "K2-BUMP", .rigging, bump, .bumper, 1.35, 0.15, 0.60, kg: 45, W: 0, "Cadre d'accroche K2")
    c.add("d&b audiotechnik", "GSL Flying frame", .rigging, bump, .bumper, 1.30, 0.15, 0.60, kg: 50, W: 0, "Cadre d'accroche GSL")
    c.add("Générique", "Bumper line array", .rigging, bump, .bumper, 1.20, 0.15, 0.60, kg: 35, W: 0, "Cadre d'accroche")
    c.add("Générique", "Élingue ronde 2 m", .rigging, acc, .spanset, 0.05, 2.00, 0.05, kg: 0.5, W: 0, "Spanset 2 t")
    c.add("Générique", "Élingue ronde 1 m", .rigging, acc, .spanset, 0.05, 1.00, 0.05, kg: 0.3, W: 0, "Spanset 2 t")
    c.add("Générique", "Bride + manille", .rigging, acc, .spanset, 0.05, 0.50, 0.05, kg: 1, W: 0, "Bridle 2 brins")
    c.add("Générique", "Pied de levage Genie 6 m", .rigging, acc, .trussTower, 0.80, 6.00, 0.80, kg: 120, W: 0, "Tour de levage manuelle")
}

// MARK: - Staging

private func addStaging(_ c: inout CatalogBuilder) {
    let deck = "Praticables", stairs = "Escaliers", riser = "Risers", barrier = "Barrières"
    struct Deck { let brand: String; let name: String; let w: Float; let d: Float }
    let decks = [
        Deck(brand: "Litedeck", name: "2×1 m", w: 2, d: 1),
        Deck(brand: "Litedeck", name: "8'×4'", w: 2.44, d: 1.22),
        Deck(brand: "Prolyte", name: "StageDex 2×1 m", w: 2, d: 1),
        Deck(brand: "Prolyte", name: "StageDex 1×1 m", w: 1, d: 1),
        Deck(brand: "Steeldeck", name: "8'×4'", w: 2.44, d: 1.22),
        Deck(brand: "Nivoflex", name: "2×1 m", w: 2, d: 1),
        Deck(brand: "Bütec", name: "2×1 m", w: 2, d: 1),
        Deck(brand: "Megadeck", name: "2×1 m", w: 2, d: 1),
    ]
    let heights: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.6, 2.0]
    for d in decks {
        for h in heights {
            c.add(d.brand, "\(d.name) H\(Int(h * 100)) cm", .staging, deck, .stageDeck, d.w, h, d.d,
                  kg: 30 + 8 * h, W: 0, "Praticable 750 kg/m²")
        }
    }
    // Assembled stages
    for (w, d, h) in [(Float(6), Float(4), Float(0.8)), (8, 6, 1.0), (10, 8, 1.2), (12, 10, 1.5), (16, 12, 1.8), (20, 14, 2.0)] {
        c.add("Générique", "Scène \(Int(w))×\(Int(d)) m H\(Int(h * 100))", .staging, "Scènes assemblées", .stageDeck,
              w, h, d, kg: w * d * 35, W: 0, "Scène praticables assemblée")
    }
    c.add("Générique", "Avancée de scène 4×2 m", .staging, "Scènes assemblées", .stageDeck, 4, 1.0, 2, kg: 280, W: 0, "Thrust")
    c.add("Générique", "Catwalk 10×2 m", .staging, "Scènes assemblées", .stageDeck, 2, 1.0, 10, kg: 700, W: 0, "Avancée longue")
    c.add("Générique", "B-stage rond Ø4 m", .staging, "Scènes assemblées", .stageDeck, 4, 1.0, 4, kg: 450, W: 0, "Scène secondaire")
    for h: Float in [0.4, 0.8, 1.2, 1.6, 2.0] {
        c.add("Générique", "Escalier H\(Int(h * 100)) cm", .staging, stairs, .stairs, 1.0, h, max(0.6, h * 1.3), kg: 20 + 15 * h, W: 0, "Escalier avec rampe")
    }
    c.add("Générique", "Rolling riser 2.4×2.4 m H40", .staging, riser, .rollingRiser, 2.44, 0.40, 2.44, kg: 160, W: 0, "Praticable roulant batterie")
    c.add("Générique", "Rolling riser 2.4×1.8 m H40", .staging, riser, .rollingRiser, 2.44, 0.40, 1.83, kg: 130, W: 0, "Praticable roulant claviers")
    c.add("Générique", "Rolling riser 3×2.4 m H60", .staging, riser, .rollingRiser, 3.0, 0.60, 2.44, kg: 200, W: 0, "Praticable roulant")
    c.add("Mojo", "Barrier 1 m", .staging, barrier, .barrier, 1.0, 1.20, 1.0, kg: 75, W: 0, "Crash barrier aluminium")
    c.add("Mojo", "Barrier angle 45°", .staging, barrier, .barrier, 1.0, 1.20, 1.0, kg: 80, W: 0, "Angle crash barrier")
    c.add("Générique", "Barrière Vauban 2 m", .staging, barrier, .barrier, 2.0, 1.10, 0.5, kg: 15, W: 0, "Barrière de foule")
    c.add("Générique", "Barrière Heras 3.5 m", .staging, barrier, .barrier, 3.5, 2.00, 0.6, kg: 22, W: 0, "Clôture de chantier")
}

// MARK: - SFX

private func addSFX(_ c: inout CatalogBuilder) {
    let co2 = "CO2 & Jets", spark = "Étincelles froides", conf = "Confettis", flame = "Flammes"
    c.add("MagicFX", "CO2 Jet", .sfx, co2, .sfxJet, 0.25, 0.40, 0.25, kg: 7, W: 50, "Jet CO2 8 m")
    c.add("MagicFX", "Power Jet", .sfx, co2, .sfxJet, 0.30, 0.45, 0.30, kg: 10, W: 50, "Jet CO2 haute puissance")
    c.add("MagicFX", "Sparkular", .sfx, spark, .sparkular, 0.30, 0.35, 0.30, kg: 11, W: 700, "Fontaine étincelles froides 1–5 m")
    c.add("MagicFX", "Sparkular Fall", .sfx, spark, .sparkular, 0.30, 0.25, 0.30, kg: 9, W: 700, "Cascade étincelles froides")
    c.add("MagicFX", "Stadium Shot III", .sfx, conf, .confettiCannon, 0.40, 0.70, 0.40, kg: 35, W: 100, "Canon confettis/serpentins 30 m")
    c.add("MagicFX", "Swirl Fan", .sfx, conf, .confettiCannon, 0.60, 0.80, 0.40, kg: 25, W: 300, "Ventilateur confettis")
    c.add("MagicFX", "Flamaniac", .sfx, flame, .flameUnit, 0.40, 0.35, 0.40, kg: 25, W: 100, "Flamme 8 m")
    c.add("MagicFX", "Super Shot", .sfx, conf, .confettiCannon, 0.10, 0.60, 0.10, kg: 2, W: 0, "Tube confetti électrique")
    c.add("Showven", "Sparkular Pro", .sfx, spark, .sparkular, 0.30, 0.35, 0.30, kg: 11, W: 750, "Étincelles froides")
    c.add("Le Maitre", "G-Flame", .sfx, flame, .flameUnit, 0.40, 0.35, 0.40, kg: 22, W: 100, "Projecteur de flammes")
    c.add("Galaxis", "G-Flame Projector", .sfx, flame, .flameUnit, 0.40, 0.40, 0.40, kg: 30, W: 100, "Flammes tournée")
    c.add("Look Solutions", "Cryo-Fog", .sfx, co2, .hazer, 0.60, 0.40, 0.40, kg: 30, W: 1000, "Fumée lourde")
    c.add("Générique", "Machine à neige", .sfx, conf, .hazer, 0.50, 0.30, 0.30, kg: 12, W: 900, "Neige artificielle")
    c.add("Générique", "Machine à bulles", .sfx, conf, .hazer, 0.40, 0.30, 0.30, kg: 8, W: 100, "Bulles")
    c.add("Générique", "Ventilateur turbine", .sfx, co2, .sfxJet, 0.60, 0.70, 0.40, kg: 30, W: 1000, "Ventilateur d'effet")
}

// MARK: - Control

private func addControl(_ c: inout CatalogBuilder) {
    let audio = "Consoles son", light = "Consoles lumière"
    c.add("DiGiCo", "SD7 Quantum", .control, audio, .mixingConsole, 1.84, 0.45, 0.88, kg: 125, W: 900, "Console son tournée")
    c.add("DiGiCo", "Quantum 338", .control, audio, .mixingConsole, 1.40, 0.42, 0.74, kg: 70, W: 600, "Console son")
    c.add("DiGiCo", "Quantum 7", .control, audio, .mixingConsole, 1.84, 0.45, 0.88, kg: 125, W: 900, "Console son")
    c.add("DiGiCo", "SD12", .control, audio, .mixingConsole, 1.10, 0.38, 0.72, kg: 50, W: 400, "Console son compacte")
    c.add("Avid", "VENUE S6L-32D", .control, audio, .mixingConsole, 1.60, 0.38, 0.80, kg: 60, W: 500, "Console son")
    c.add("Yamaha", "RIVAGE PM10", .control, audio, .mixingConsole, 1.80, 0.45, 0.90, kg: 90, W: 600, "Console son")
    c.add("Yamaha", "RIVAGE PM5", .control, audio, .mixingConsole, 1.50, 0.40, 0.80, kg: 70, W: 500, "Console son")
    c.add("Yamaha", "CL5", .control, audio, .mixingConsole, 1.05, 0.30, 0.67, kg: 36, W: 300, "Console son")
    c.add("Allen & Heath", "dLive S7000", .control, audio, .mixingConsole, 1.47, 0.33, 0.75, kg: 52, W: 300, "Console son")
    c.add("Allen & Heath", "Avantis", .control, audio, .mixingConsole, 1.00, 0.25, 0.60, kg: 25, W: 200, "Console son")
    c.add("Midas", "Heritage-D HD96-24", .control, audio, .mixingConsole, 1.10, 0.35, 0.70, kg: 40, W: 300, "Console son")
    c.add("Midas", "PRO X", .control, audio, .mixingConsole, 1.50, 0.40, 0.90, kg: 70, W: 500, "Console son")
    c.add("SSL", "Live L550 Plus", .control, audio, .mixingConsole, 1.80, 0.45, 0.88, kg: 90, W: 600, "Console son")
    c.add("Behringer", "Wing", .control, audio, .mixingConsole, 0.80, 0.25, 0.55, kg: 20, W: 150, "Console son compacte")
    c.add("MA Lighting", "grandMA3 full-size", .control, light, .lightingConsole, 1.40, 0.40, 0.70, kg: 80, W: 600, "Console lumière")
    c.add("MA Lighting", "grandMA3 light", .control, light, .lightingConsole, 1.10, 0.35, 0.65, kg: 50, W: 450, "Console lumière")
    c.add("MA Lighting", "grandMA3 compact XT", .control, light, .lightingConsole, 0.85, 0.25, 0.55, kg: 20, W: 250, "Console lumière compacte")
    c.add("MA Lighting", "grandMA3 onPC command wing", .control, light, .lightingConsole, 0.65, 0.15, 0.45, kg: 10, W: 100, "Surface onPC")
    c.add("ChamSys", "MagicQ MQ500M", .control, light, .lightingConsole, 1.10, 0.30, 0.65, kg: 35, W: 300, "Console lumière")
    c.add("ChamSys", "MagicQ MQ250M", .control, light, .lightingConsole, 0.85, 0.25, 0.55, kg: 20, W: 200, "Console lumière")
    c.add("Avolites", "Diamond 9", .control, light, .lightingConsole, 1.40, 0.40, 0.75, kg: 75, W: 500, "Console lumière")
    c.add("Avolites", "Arena", .control, light, .lightingConsole, 1.10, 0.30, 0.65, kg: 40, W: 300, "Console lumière")
    c.add("High End Systems", "Hog 4", .control, light, .lightingConsole, 1.20, 0.35, 0.70, kg: 50, W: 400, "Console lumière")
    c.add("ETC", "Eos Apex 20", .control, light, .lightingConsole, 1.30, 0.35, 0.70, kg: 55, W: 400, "Console lumière théâtre")
    c.add("Générique", "Régie FOH 3×3 m", .control, "Régie", .tent, 3, 2.6, 3, kg: 200, W: 0, "Praticable + couverture régie façade")
    c.add("Générique", "Régie retours (monitor world)", .control, "Régie", .table, 2.4, 0.9, 1.2, kg: 80, W: 0, "Table régie retours")
}

// MARK: - Power

private func addPower(_ c: inout CatalogBuilder) {
    let distro = "Distribution", gen = "Groupes électrogènes", cable = "Câblage"
    c.add("Générique", "Distro Powerlock 400 A", .power, distro, .distroBox, 0.60, 0.80, 0.50, kg: 80, W: 0, "Armoire 400 A triphasé")
    c.add("Générique", "Distro 125 A → 63/32/16", .power, distro, .distroBox, 0.60, 0.70, 0.50, kg: 60, W: 0, "Armoire de distribution")
    c.add("Générique", "Distro 63 A", .power, distro, .distroBox, 0.50, 0.50, 0.40, kg: 30, W: 0, "Coffret 63 A")
    c.add("Générique", "Distro 32 A", .power, distro, .distroBox, 0.40, 0.40, 0.30, kg: 18, W: 0, "Coffret 32 A")
    c.add("Générique", "Rack gradateurs 24×2.3 kW", .power, distro, .ampRack, 0.60, 1.00, 0.70, kg: 90, W: 0, "Dimmer rack")
    c.add("Générique", "Splitter DMX/Art-Net", .power, distro, .distroBox, 0.50, 0.30, 0.40, kg: 10, W: 100, "Node réseau lumière")
    c.add("Aggreko", "Groupe 500 kVA", .power, gen, .generator, 6.00, 2.60, 2.40, kg: 9000, W: 0, "Container insonorisé")
    c.add("Aggreko", "Groupe 200 kVA", .power, gen, .generator, 4.20, 2.20, 1.50, kg: 4000, W: 0, "Groupe insonorisé")
    c.add("Générique", "Groupe 60 kVA", .power, gen, .generator, 2.80, 1.60, 1.10, kg: 1500, W: 0, "Groupe insonorisé")
    c.add("Défender", "Passe-câble 5 canaux", .power, cable, .cableRamp, 0.90, 0.07, 0.60, kg: 18, W: 0, "Protège-câble")
    c.add("Défender", "Passe-câble 3 canaux", .power, cable, .cableRamp, 0.90, 0.05, 0.50, kg: 12, W: 0, "Protège-câble")
    c.add("Générique", "Multipaire scène → FOH 50 m", .power, cable, .roadCase, 0.80, 0.60, 0.60, kg: 60, W: 0, "Touret multipaire")
}

// MARK: - Backline

private func addBackline(_ c: inout CatalogBuilder) {
    let drums = "Batteries", amps = "Amplis", keys = "Claviers"
    c.add("DW", "Collector's Series kit", .backline, drums, .drumKit, 1.80, 1.40, 1.50, kg: 60, W: 0, "Batterie 5 fûts + cymbales")
    c.add("Pearl", "Reference kit", .backline, drums, .drumKit, 1.80, 1.40, 1.50, kg: 60, W: 0, "Batterie 5 fûts")
    c.add("Yamaha", "Recording Custom kit", .backline, drums, .drumKit, 1.80, 1.40, 1.50, kg: 58, W: 0, "Batterie 5 fûts")
    c.add("Ludwig", "Classic Maple kit", .backline, drums, .drumKit, 1.70, 1.40, 1.40, kg: 55, W: 0, "Batterie 4 fûts")
    c.add("Roland", "V-Drums VAD706", .backline, drums, .drumKit, 1.60, 1.30, 1.40, kg: 45, W: 100, "Batterie électronique")
    c.add("Marshall", "JCM800 Stack", .backline, amps, .guitarAmp, 0.76, 1.70, 0.36, kg: 80, W: 200, "Tête + 2 baffles 4×12\"")
    c.add("Marshall", "JCM800 Half stack", .backline, amps, .guitarAmp, 0.76, 1.00, 0.36, kg: 45, W: 200, "Tête + baffle 4×12\"")
    c.add("Fender", "Twin Reverb", .backline, amps, .guitarAmp, 0.67, 0.50, 0.27, kg: 30, W: 200, "Combo 2×12\"")
    c.add("Fender", "Hot Rod Deluxe", .backline, amps, .guitarAmp, 0.60, 0.47, 0.27, kg: 20, W: 100, "Combo 1×12\"")
    c.add("Vox", "AC30", .backline, amps, .guitarAmp, 0.70, 0.56, 0.26, kg: 32, W: 150, "Combo 2×12\"")
    c.add("Mesa/Boogie", "Dual Rectifier Stack", .backline, amps, .guitarAmp, 0.75, 1.70, 0.36, kg: 85, W: 250, "Tête + 2 baffles")
    c.add("Orange", "Rockerverb Half stack", .backline, amps, .guitarAmp, 0.76, 1.00, 0.36, kg: 45, W: 200, "Tête + baffle")
    c.add("Ampeg", "SVT-CL + 8×10", .backline, amps, .bassAmp, 0.62, 1.60, 0.40, kg: 75, W: 400, "Stack basse")
    c.add("Ampeg", "SVT-410HLF", .backline, amps, .bassAmp, 0.62, 0.70, 0.40, kg: 35, W: 0, "Baffle basse 4×10\"")
    c.add("Darkglass", "Microtubes 900 + 4×10", .backline, amps, .bassAmp, 0.62, 0.80, 0.40, kg: 40, W: 300, "Stack basse")
    c.add("Steinway", "Model D", .backline, keys, .piano, 1.57, 1.02, 2.74, kg: 480, W: 0, "Piano de concert à queue")
    c.add("Yamaha", "C3X", .backline, keys, .piano, 1.49, 1.01, 1.86, kg: 320, W: 0, "Piano à queue")
    c.add("Yamaha", "CP88 + stand", .backline, keys, .keyboardStand, 1.30, 0.95, 0.40, kg: 30, W: 50, "Piano de scène")
    c.add("Nord", "Stage 4 + stand", .backline, keys, .keyboardStand, 1.30, 0.95, 0.40, kg: 28, W: 50, "Clavier de scène")
    c.add("Hammond", "B-3 + Leslie 122", .backline, keys, .piano, 1.25, 1.00, 0.70, kg: 190, W: 300, "Orgue + cabine Leslie")
    c.add("Pioneer DJ", "Booth CDJ-3000 ×2 + DJM-A9", .backline, "DJ", .table, 1.60, 1.05, 0.80, kg: 60, W: 300, "Régie DJ sur table")
    c.add("Technics", "SL-1200 ×2 + table", .backline, "DJ", .table, 1.60, 1.05, 0.80, kg: 55, W: 100, "Platines vinyle")
}

// MARK: - Venue / furniture / safety

private func addVenue(_ c: inout CatalogBuilder) {
    let furn = "Mobilier", cases = "Flight cases", tents = "Tentes & abris"
    c.add("Générique", "Table technique 1.8×0.75 m", .venue, furn, .table, 1.80, 0.75, 0.75, kg: 15, W: 0, "Table pliante")
    c.add("Générique", "Table mange-debout", .venue, furn, .table, 0.80, 1.10, 0.80, kg: 10, W: 0, "Table haute")
    c.add("Générique", "Chaise", .venue, furn, .chair, 0.45, 0.85, 0.50, kg: 4, W: 0, "Chaise pliante")
    c.add("Générique", "Tabouret haut", .venue, furn, .chair, 0.40, 0.75, 0.40, kg: 4, W: 0, "Tabouret bar")
    c.add("Générique", "Fauteuil plateau TV", .venue, furn, .chair, 0.75, 0.85, 0.75, kg: 15, W: 0, "Fauteuil interview")
    c.add("Générique", "Flight case 120×60×60", .venue, cases, .roadCase, 1.20, 0.60, 0.60, kg: 40, W: 0, "Road case standard")
    c.add("Générique", "Flight case moving heads ×2", .venue, cases, .roadCase, 1.20, 0.90, 0.60, kg: 55, W: 0, "Case 2 lyres")
    c.add("Générique", "Flight case câble 100×60×60", .venue, cases, .roadCase, 1.00, 0.60, 0.60, kg: 30, W: 0, "Malle à câbles")
    c.add("Générique", "Rack 19\" 12U", .venue, cases, .ampRack, 0.60, 0.80, 0.60, kg: 30, W: 0, "Rack 12U")
    c.add("Générique", "Tente pliante 3×3 m", .venue, tents, .tent, 3.0, 3.0, 3.0, kg: 40, W: 0, "Barnum")
    c.add("Générique", "Tente pliante 6×3 m", .venue, tents, .tent, 6.0, 3.0, 3.0, kg: 70, W: 0, "Barnum")
    c.add("Générique", "Loge / dressing 6×3 m", .venue, tents, .tent, 6.0, 2.6, 3.0, kg: 1800, W: 0, "Container loge")
}
