//
//  StageViewModel.swift
//  VisionStage
//

import SwiftUI
import Combine

// MARK: - View Model

class StageViewModel: ObservableObject {
    static let immersiveSpaceID = "StageSpace"

    @Published var elements: [StageElement] = []
    @Published var selectedElement: StageElement?
    @Published var isImmersiveSpaceOpen = false
    @Published var eventInfo = EventInfo()
    @Published var showAddSheet = false
    @Published var showEventSheet = false

    init() {
        loadDefaultStage()
    }

    /// A festival-style demo rig built from real library products.
    func loadDefaultStage() {
        var rig: [StageElement] = []
        func put(_ id: String, _ x: Float, _ y: Float, _ z: Float, rot: Float = 0,
                 qty: Int = 1, color: StageElement.ElementColor = .white, name: String? = nil) {
            guard let p = ProductLibrary.product(id: id) else {
                assertionFailure("Unknown product id \(id)")
                return
            }
            rig.append(StageElement(name: name ?? p.model, type: p.elementType,
                                    position: [x, y, z], rotation: rot, scale: 1,
                                    color: color, isActive: true, notes: "", productID: p.id, quantity: qty))
        }

        // Stage, roof & wings (stage front edge at z = -3, deck height 1.5 m)
        put("generique-scene-12-10-m-h150", 0, 0, -8, color: .blue, name: "Scène principale 12×10")
        put("prolyte-st-roof-14-12-m", 0, 0, -8, name: "Toit de scène 14×12")
        put("generique-escalier-h160-cm", -5.5, 0, -12.5, rot: 90, name: "Escalier jardin")

        // Video
        put("generique-mur-led-10-5-6-m", 0, 1.6, -12.6, color: .purple, name: "Mur LED lointain")
        put("generique-ecran-led-lateral-3-5-m", -10.5, 2.5, -3.5, rot: 15, color: .purple, name: "IMAG jardin")
        put("generique-ecran-led-lateral-3-5-m", 10.5, 2.5, -3.5, rot: -15, color: .purple, name: "IMAG cour")

        // PA
        put("l-acoustics-k2", -7.8, 8.4, -2.6, rot: 8, qty: 12, name: "K2 gauche ×12")
        put("l-acoustics-k2", 7.8, 8.4, -2.6, rot: -8, qty: 12, name: "K2 droite ×12")
        put("l-acoustics-ks28", 0, 0, -2.4, qty: 6, name: "KS28 ×6")
        put("l-acoustics-kara-ii", -4, 0, -2.4, rot: 20, qty: 2, name: "Front-fill G")
        put("l-acoustics-kara-ii", 4, 0, -2.4, rot: -20, qty: 2, name: "Front-fill D")

        // Lighting: front truss (spots), mid truss (washes), stage floor (bars)
        for (i, x) in [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0].enumerated() {
            put("robe-megapointe", Float(x), 8.5, -2.4, color: .white, name: "MegaPointe \(i + 1)")
            put("martin-mac-aura-xb", Float(x), 8.5, -8, color: .blue, name: "Aura XB \(i + 1)")
            put("clay-paky-sharpy", Float(x), 8.5, -13.6, color: .purple, name: "Sharpy \(i + 1)")
        }
        for (i, x) in [-4.5, -1.5, 1.5, 4.5].enumerated() {
            put("glp-impression-x4-bar-20", Float(x), 1.5, -3.4, color: .orange, name: "X4 Bar \(i + 1)")
        }
        put("chauvet-professional-strike-array-4", -6, 1.5, -3.4, color: .yellow, name: "Blinder G")
        put("chauvet-professional-strike-array-4", 6, 1.5, -3.4, color: .yellow, name: "Blinder D")
        put("martin-atomic-3000-led", 0, 8.5, -5.2, name: "Atomic 3000 LED")
        put("look-solutions-unique-2-1", 5.5, 1.5, -12.5, name: "Hazer")

        // Backline
        put("generique-rolling-riser-2-4-2-4-m-h40", 0, 1.5, -10, color: .red, name: "Riser batterie")
        put("dw-collector-s-series-kit", 0, 1.9, -10.2, color: .red, name: "Batterie")
        put("marshall-jcm800-stack", -3.5, 1.5, -11, name: "Ampli guitare")
        put("ampeg-svt-cl-8-10", 3.5, 1.5, -11, name: "Ampli basse")
        put("nord-stage-4-stand", 5, 1.5, -8.5, rot: -30, name: "Claviers")
        put("shure-sm58-pied", 0, 1.5, -5, name: "Micro chant")
        put("d-b-audiotechnik-m4", -1.2, 1.5, -4, name: "Wedge 1")
        put("d-b-audiotechnik-m4", 1.2, 1.5, -4, name: "Wedge 2")

        // SFX
        put("magicfx-sparkular", -5, 1.5, -3.6, name: "Sparkular G")
        put("magicfx-sparkular", 5, 1.5, -3.6, name: "Sparkular D")
        put("magicfx-co2-jet", -3, 1.5, -3.6, name: "CO2 G")
        put("magicfx-co2-jet", 3, 1.5, -3.6, name: "CO2 D")

        // FOH
        put("generique-regie-foh-3-3-m", 0, 0, 7, name: "Régie façade")
        put("digico-sd7-quantum", -0.8, 0, 7, name: "Console son")
        put("ma-lighting-grandma3-full-size", 0.9, 0, 7, name: "Console lumière")
        put("robert-juliat-cyrano-2500", -2.5, 0, 8, name: "Poursuite 1")
        put("robert-juliat-cyrano-2500", 2.5, 0, 8, name: "Poursuite 2")
        put("sony-hdc-3500", -4, 0, 6, name: "Caméra 1")
        put("generique-distro-powerlock-400-a", 9, 0, -12, name: "Distro 400 A")

        elements = rig
    }

    func addElement(_ element: StageElement) {
        elements.append(element)
    }

    /// Adds a library product at a sensible default spot for its category.
    func addProduct(_ product: LibraryProduct, quantity: Int? = nil) {
        let sameKind = elements.filter { $0.product?.category == product.category }.count
        let spread = Float(sameKind % 7 - 3)            // −3 … 3 m, so new items don't overlap
        let pos: SIMD3<Float>
        switch product.category {
        case .staging:  pos = [0, 0, -8]
        case .truss:    pos = product.shape == .roofSystem || product.shape == .mobileStage || product.shape == .trussTower || product.shape == .basePlate
                              ? [0, 0, -8] : [0, 7, -6]
        case .lighting: pos = product.shape == .followspot || product.shape == .hazer ? [spread, 0, 6] : [spread * 1.5, 7, -6]
        case .audio:
            switch product.shape {
            case .lineArrayBox: pos = [spread < 0 ? -7.8 : 7.8, 8.4, -2.6]
            case .subwoofer:    pos = [0, 0, -2.4]
            default:            pos = [spread, 0, -3]
            }
        case .video:    pos = product.shape == .ledPanel || product.shape == .projectionScreen ? [0, 0, -12] : [spread, 0, 5]
        case .rigging:  pos = [spread, 7.5, -6]
        case .control:  pos = [spread, 0, 7]
        default:        pos = [spread, 0, -4]
        }
        let element = StageElement(name: product.model, type: product.elementType,
                                   position: pos, rotation: 0, scale: 1,
                                   color: product.category == .lighting ? .white : .blue,
                                   isActive: true, notes: product.specs,
                                   productID: product.id,
                                   quantity: quantity ?? (product.shape == .lineArrayBox ? 8 : 1))
        elements.append(element)
        selectedElement = element
    }

    func removeElement(_ element: StageElement) {
        elements.removeAll { $0.id == element.id }
        if selectedElement?.id == element.id { selectedElement = nil }
    }

    func updateElement(_ element: StageElement) {
        if let index = elements.firstIndex(where: { $0.id == element.id }) {
            elements[index] = element
        }
    }

    func toggleActive(_ element: StageElement) {
        if let index = elements.firstIndex(where: { $0.id == element.id }) {
            elements[index].isActive.toggle()
        }
        // Keep the open detail view in sync with the list.
        if selectedElement?.id == element.id {
            selectedElement?.isActive.toggle()
        }
    }
}
