//
//  ProductModelFactory.swift
//  VisionStage
//
//  Builds a recognisable procedural 3D model for each product shape, sized
//  from the product's real dimensions. Conventions:
//   • the model sits on y = 0 (its base) and is centred on x/z,
//   • the "front" (audience side) faces +z,
//   • light fixtures are built pointing up (+y); hung fixtures get flipped.
//

import RealityKit
import UIKit
import simd

struct ModelSpec {
    var shape: ProductShape
    var width: Float
    var height: Float
    var depth: Float
    var accent: UIColor
    var quantity: Int = 1
    /// True when the element is flown/hung (above the floor).
    var elevated: Bool = false
}

enum ProductModelFactory {

    // MARK: Materials (shared)

    static let body: Material = pbr(UIColor(white: 0.07, alpha: 1), rough: 0.55, metal: 0.4)
    static let bodyGrey: Material = pbr(UIColor(white: 0.22, alpha: 1), rough: 0.6, metal: 0.3)
    static let alu: Material = pbr(UIColor(white: 0.82, alpha: 1), rough: 0.25, metal: 1.0)
    static let steel: Material = pbr(UIColor(white: 0.45, alpha: 1), rough: 0.35, metal: 0.9)
    static let grille: Material = pbr(UIColor(white: 0.12, alpha: 1), rough: 0.9, metal: 0.0)
    static let deckTop: Material = pbr(UIColor(white: 0.09, alpha: 1), rough: 0.85, metal: 0.0)
    static let skirt: Material = pbr(UIColor(white: 0.03, alpha: 1), rough: 1.0, metal: 0.0)
    static let wood: Material = pbr(UIColor(red: 0.45, green: 0.3, blue: 0.18, alpha: 1), rough: 0.6, metal: 0.0)
    static let pianoBlack: Material = pbr(UIColor(white: 0.02, alpha: 1), rough: 0.08, metal: 0.2)
    static let white: Material = pbr(UIColor(white: 0.92, alpha: 1), rough: 0.7, metal: 0.0)
    static let yellow: Material = pbr(.systemYellow, rough: 0.5, metal: 0.1)
    static let red: Material = pbr(.systemRed, rough: 0.5, metal: 0.1)
    static let tolex: Material = pbr(UIColor(white: 0.05, alpha: 1), rough: 0.95, metal: 0.0)
    static let cloth: Material = pbr(UIColor(red: 0.6, green: 0.55, blue: 0.45, alpha: 1), rough: 1.0, metal: 0.0)
    static let canopy: Material = {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(white: 0.9, alpha: 1))
        m.roughness = 0.8
        m.blending = .transparent(opacity: 0.55)
        m.faceCulling = .none
        return m
    }()

    static func pbr(_ c: UIColor, rough: Float, metal: Float) -> Material {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: c)
        m.roughness = .init(floatLiteral: rough)
        m.metallic = .init(floatLiteral: metal)
        return m
    }

    static func glow(_ c: UIColor) -> Material {
        UnlitMaterial(color: c)
    }

    static func beam(_ c: UIColor, opacity: Float = 0.18) -> Material {
        var m = UnlitMaterial(color: c)
        m.blending = .transparent(opacity: .init(floatLiteral: opacity))
        m.faceCulling = .none
        return m
    }

    // MARK: Mesh cache

    private static var meshCache: [String: MeshResource] = [:]

    private static func key(_ parts: Float...) -> String {
        parts.map { String(Int(($0 * 1000).rounded())) }.joined(separator: ",")
    }

    static func boxMesh(_ w: Float, _ h: Float, _ d: Float, corner: Float = 0) -> MeshResource {
        let k = "b" + key(w, h, d, corner)
        if let m = meshCache[k] { return m }
        let c = min(corner, min(w, min(h, d)) / 2 * 0.99)
        let m = MeshResource.generateBox(width: max(w, 0.001), height: max(h, 0.001), depth: max(d, 0.001), cornerRadius: max(c, 0))
        meshCache[k] = m
        return m
    }

    static func cylMesh(_ h: Float, _ r: Float) -> MeshResource {
        let k = "c" + key(h, r)
        if let m = meshCache[k] { return m }
        let m = MeshResource.generateCylinder(height: max(h, 0.001), radius: max(r, 0.001))
        meshCache[k] = m
        return m
    }

    static func coneMesh(_ h: Float, _ r: Float) -> MeshResource {
        let k = "k" + key(h, r)
        if let m = meshCache[k] { return m }
        let m = MeshResource.generateCone(height: max(h, 0.001), radius: max(r, 0.001))
        meshCache[k] = m
        return m
    }

    static func sphereMesh(_ r: Float) -> MeshResource {
        let k = "s" + key(r)
        if let m = meshCache[k] { return m }
        let m = MeshResource.generateSphere(radius: max(r, 0.001))
        meshCache[k] = m
        return m
    }

    // MARK: Builder

    final class Builder {
        let root = Entity()

        @discardableResult
        func box(_ w: Float, _ h: Float, _ d: Float, _ m: Material,
                 at p: SIMD3<Float>, corner: Float = 0, rot: simd_quatf? = nil, parent: Entity? = nil) -> ModelEntity {
            let e = ModelEntity(mesh: boxMesh(w, h, d, corner: corner), materials: [m])
            e.position = p
            if let rot { e.orientation = rot }
            (parent ?? root).addChild(e)
            return e
        }

        /// Cylinder with its axis along `axis` (default: vertical).
        @discardableResult
        func cyl(_ h: Float, _ r: Float, _ m: Material, at p: SIMD3<Float>,
                 axis: SIMD3<Float> = [0, 1, 0], parent: Entity? = nil) -> ModelEntity {
            let e = ModelEntity(mesh: cylMesh(h, r), materials: [m])
            e.position = p
            e.orientation = orient(axis)
            (parent ?? root).addChild(e)
            return e
        }

        /// Cone whose apex sits at `apex` and that opens towards `direction`.
        @discardableResult
        func cone(length: Float, radius: Float, _ m: Material, apex: SIMD3<Float>,
                  direction: SIMD3<Float>, parent: Entity? = nil) -> ModelEntity {
            let dir = simd_normalize(direction)
            let e = ModelEntity(mesh: coneMesh(length, radius), materials: [m])
            // RealityKit cones are centred with the apex towards +y: point the
            // apex back towards the source so the cone widens along `dir`.
            e.orientation = orient(-dir)
            e.position = apex + dir * (length / 2)
            (parent ?? root).addChild(e)
            return e
        }

        @discardableResult
        func sphere(_ r: Float, _ m: Material, at p: SIMD3<Float>, parent: Entity? = nil) -> ModelEntity {
            let e = ModelEntity(mesh: sphereMesh(r), materials: [m])
            e.position = p
            (parent ?? root).addChild(e)
            return e
        }

        /// A tube from a to b (truss chords, diagonals, stand legs...).
        func member(_ a: SIMD3<Float>, _ b: SIMD3<Float>, r: Float, _ m: Material, parent: Entity? = nil) {
            let v = b - a
            let len = simd_length(v)
            guard len > 0.0005 else { return }
            cyl(len, r, m, at: (a + b) / 2, axis: v / len, parent: parent)
        }

        func orient(_ axis: SIMD3<Float>) -> simd_quatf {
            let up = SIMD3<Float>(0, 1, 0)
            let a = simd_normalize(axis)
            if simd_dot(a, up) < -0.9999 { return simd_quatf(angle: .pi, axis: [1, 0, 0]) }
            return simd_quatf(from: up, to: a)
        }
    }

    // MARK: Entry point

    static func makeModel(_ s: ModelSpec) -> Entity {
        let b = Builder()
        let w = s.width, h = s.height, d = s.depth
        switch s.shape {
        // Lighting
        case .movingHead:      movingHead(b, w, h, d, s.accent, wash: false)
        case .movingHeadWash:  movingHead(b, w, h, d, s.accent, wash: true)
        case .movingBar:       movingBar(b, w, h, d, s.accent)
        case .parCan:          parCan(b, w, h, d, s.accent)
        case .ledPar:          ledPar(b, w, h, d, s.accent)
        case .ledBatten:       batten(b, w, h, d, s.accent)
        case .strobe:          strobe(b, w, h, d, s.accent)
        case .blinder:         blinder(b, w, h, d, s.accent)
        case .profileSpot:     profile(b, w, h, d, s.accent)
        case .fresnel:         fresnel(b, w, h, d, s.accent)
        case .followspot:      followspot(b, w, h, d, s.accent)
        case .laser:           laser(b, w, h, d, s.accent)
        case .hazer:           hazer(b, w, h, d)
        case .tube:            tube(b, w, h, d, s.accent)
        case .panel:           panel(b, w, h, d, s.accent)
        // Audio
        case .lineArrayBox:    lineArray(b, w, h, d, count: s.quantity, hung: s.elevated)
        case .pointSource:     pointSource(b, w, h, d)
        case .subwoofer:       subwoofers(b, w, h, d, count: s.quantity)
        case .wedge:           wedge(b, w, h, d)
        case .columnSpeaker:   column(b, w, h, d)
        case .ampRack:         rack(b, w, h, d, s.accent)
        case .microphone:      microphone(b, w, h, d)
        // Video
        case .ledPanel:        ledWall(b, w, h, d, s.accent)
        case .projector:       projector(b, w, h, d, s.accent)
        case .camera:          camera(b, w, h, d)
        case .ptzCamera:       ptz(b, w, h, d)
        case .projectionScreen: screen(b, w, h, d)
        case .mediaServer:     rack(b, w, h, d, s.accent)
        // Structure
        case .boxTruss:        boxTruss(b, length: w, size: h)
        case .triangleTruss:   triTruss(b, length: w, size: h)
        case .ladderTruss:     ladderTruss(b, length: w, size: h)
        case .trussTower:      tower(b, w, h, d)
        case .cornerBlock:     b.box(w, h, d, alu, at: [0, h / 2, 0], corner: 0.01)
        case .basePlate:       b.box(w, max(h, 0.015), d, steel, at: [0, max(h, 0.015) / 2, 0])
        case .roofSystem:      roof(b, w, h, d, mobile: false, s.accent)
        case .mobileStage:     roof(b, w, h, d, mobile: true, s.accent)
        // Rigging
        case .chainHoist:      hoist(b, w, h, d)
        case .bumper:          bumper(b, w, h, d)
        case .spanset:         b.cyl(h, max(w, 0.02), pbr(s.accent, rough: 0.9, metal: 0), at: [0, h / 2, 0])
        // Staging
        case .stageDeck:       deck(b, w, h, d, s.accent)
        case .stairs:          stairs(b, w, h, d)
        case .rollingRiser:    riser(b, w, h, d, s.accent)
        case .barrier:         barrier(b, w, h, d)
        // SFX
        case .sfxJet:          jet(b, w, h, d, plume: UIColor(white: 1, alpha: 1), opacity: 0.25)
        case .sparkular:       jet(b, w, h, d, plume: UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 1), opacity: 0.35)
        case .confettiCannon:  confetti(b, w, h, d, s.accent)
        case .flameUnit:       jet(b, w, h, d, plume: UIColor(red: 1, green: 0.45, blue: 0.05, alpha: 1), opacity: 0.45)
        // Control & power
        case .mixingConsole:   console(b, w, h, d, s.accent, lighting: false)
        case .lightingConsole: console(b, w, h, d, s.accent, lighting: true)
        case .distroBox:       distro(b, w, h, d)
        case .generator:       generator(b, w, h, d)
        case .cableRamp:       ramp(b, w, h, d)
        // Backline & venue
        case .drumKit:         drums(b, w, h, d, s.accent)
        case .guitarAmp:       ampStack(b, w, h, d, bass: false)
        case .bassAmp:         ampStack(b, w, h, d, bass: true)
        case .piano:           piano(b, w, h, d)
        case .keyboardStand:   keyboard(b, w, h, d)
        case .roadCase:        roadCase(b, w, h, d)
        case .table:           table(b, w, h, d)
        case .chair:           chair(b, w, h, d)
        case .tent:            tent(b, w, h, d)
        }
        return b.root
    }

    /// Fallback shape for generic elements that aren't linked to a product.
    static func defaultSpec(for type: StageElement.ElementType, accent: UIColor) -> ModelSpec {
        switch type {
        case .mainStage: return ModelSpec(shape: .stageDeck, width: 3, height: 0.3, depth: 2, accent: accent)
        case .screen:    return ModelSpec(shape: .ledPanel, width: 1.8, height: 1.0, depth: 0.08, accent: accent)
        case .lighting:  return ModelSpec(shape: .movingHead, width: 0.4, height: 0.65, depth: 0.25, accent: accent)
        case .speaker:   return ModelSpec(shape: .pointSource, width: 0.4, height: 0.8, depth: 0.4, accent: accent)
        case .camera:    return ModelSpec(shape: .camera, width: 0.4, height: 1.6, depth: 0.7, accent: accent)
        case .truss:     return ModelSpec(shape: .trussTower, width: 0.4, height: 3, depth: 0.4, accent: accent)
        case .rigging:   return ModelSpec(shape: .chainHoist, width: 0.3, height: 0.55, depth: 0.3, accent: accent)
        case .sfx:       return ModelSpec(shape: .sparkular, width: 0.3, height: 0.35, depth: 0.3, accent: accent)
        case .control:   return ModelSpec(shape: .mixingConsole, width: 1.4, height: 0.4, depth: 0.75, accent: accent)
        case .power:     return ModelSpec(shape: .distroBox, width: 0.5, height: 0.6, depth: 0.4, accent: accent)
        case .backline:  return ModelSpec(shape: .guitarAmp, width: 0.7, height: 1.0, depth: 0.35, accent: accent)
        case .table:     return ModelSpec(shape: .table, width: 1.5, height: 0.75, depth: 0.7, accent: accent)
        case .chair:     return ModelSpec(shape: .chair, width: 0.45, height: 0.85, depth: 0.5, accent: accent)
        }
    }

    // MARK: - Lighting

    static func movingHead(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor, wash: Bool) {
        let baseH = h * 0.2
        b.box(w, baseH, d, body, at: [0, baseH / 2, 0], corner: 0.02)
        b.box(w * 0.5, 0.004, 0.004, glow(.white), at: [0, baseH * 0.6, d / 2 + 0.002])  // display
        let armH = h * 0.62, armW = w * 0.12
        let armX = w / 2 - armW / 2
        b.box(w * 0.85, baseH * 0.35, d * 0.7, body, at: [0, baseH + baseH * 0.17, 0], corner: 0.01) // yoke bridge
        for sx: Float in [-1, 1] {
            b.box(armW, armH, d * 0.55, body, at: [sx * armX, baseH + armH / 2, 0], corner: 0.015)
        }
        let headR = min(w * 0.34, d * 0.9)
        let headY = baseH + armH * 0.62
        let headLen = wash ? h * 0.32 : h * 0.5
        b.cyl(w - 2 * armW - 0.01, headR * 0.35, body, at: [0, headY, 0], axis: [1, 0, 0]) // tilt axle
        b.cyl(headLen, headR, body, at: [0, headY + headLen * 0.15, 0])
        let lensY = headY + headLen * 0.65
        b.cyl(0.006, headR * (wash ? 0.92 : 0.7), glow(c), at: [0, lensY, 0])
        b.cone(length: 6, radius: wash ? 2.2 : 0.35, beam(c, opacity: wash ? 0.1 : 0.2),
               apex: [0, lensY, 0], direction: [0, 1, 0])
    }

    static func movingBar(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        let baseH = h * 0.35
        b.box(w * 0.3, baseH, d, body, at: [0, baseH / 2, 0], corner: 0.01)
        let barH = h * 0.5
        b.box(w, barH, d, body, at: [0, baseH + barH / 2 + 0.02, 0], corner: 0.01)
        let n = max(4, Int(w / 0.055))
        let step = w / Float(n)
        for i in 0..<n {
            let x = -w / 2 + step * (Float(i) + 0.5)
            b.cyl(0.005, step * 0.38, glow(c), at: [x, baseH + barH + 0.023, 0])
        }
        b.box(w, 0.01, d * 0.4, beam(c, opacity: 0.25), at: [0, baseH + barH + 0.03, 0])
        b.cone(length: 5, radius: 0.9, beam(c, opacity: 0.08), apex: [0, baseH + barH, 0], direction: [0, 1, 0])
    }

    static func parCan(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        // Yoke + can
        b.box(w * 1.1, 0.02, 0.03, steel, at: [0, 0.01, 0])
        for sx: Float in [-1, 1] { b.box(0.015, h * 0.6, 0.03, steel, at: [sx * w * 0.55, h * 0.3, 0]) }
        b.cyl(d, w / 2, body, at: [0, h * 0.5 + d * 0.15, 0])
        b.cyl(0.005, w * 0.45, glow(c), at: [0, h * 0.5 + d * 0.65, 0])
        b.cone(length: 5, radius: 0.8, beam(c, opacity: 0.14), apex: [0, h * 0.5 + d * 0.65, 0], direction: [0, 1, 0])
    }

    static func ledPar(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w * 1.05, 0.02, 0.03, steel, at: [0, 0.01, 0])
        for sx: Float in [-1, 1] { b.box(0.015, h * 0.55, 0.03, steel, at: [sx * w * 0.52, h * 0.27, 0]) }
        let r = w / 2
        b.cyl(d, r, body, at: [0, h * 0.5, 0])
        b.cyl(0.005, r * 0.85, glow(c), at: [0, h * 0.5 + d / 2 + 0.003, 0])
        b.cone(length: 4, radius: 1.2, beam(c, opacity: 0.1), apex: [0, h * 0.5 + d / 2, 0], direction: [0, 1, 0])
    }

    static func batten(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, h, d, body, at: [0, h / 2, 0], corner: 0.008)
        let n = max(3, Int(w / 0.08))
        let step = w / Float(n)
        for i in 0..<n {
            b.box(step * 0.75, 0.004, d * 0.65, glow(c), at: [-w / 2 + step * (Float(i) + 0.5), h + 0.002, 0])
        }
        b.cone(length: 4, radius: 1.0, beam(c, opacity: 0.07), apex: [0, h, 0], direction: [0, 1, 0])
    }

    static func strobe(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w * 1.05, 0.02, 0.03, steel, at: [0, 0.01, 0])
        b.box(w, d, h, body, at: [0, d / 2 + 0.03, 0], corner: 0.015)
        b.box(w * 0.88, 0.004, h * 0.6, glow(.white), at: [0, d + 0.032, 0])
        b.box(w * 0.95, 0.003, h * 0.85, beam(c, opacity: 0.5), at: [0, d + 0.034, 0])
    }

    static func blinder(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, d, h, body, at: [0, d / 2, 0], corner: 0.01)
        let cells = max(1, Int((w / 0.15).rounded()))
        let cols = cells >= 4 ? cells / 2 : cells
        let rows = cells >= 4 ? 2 : 1
        let cw = w / Float(cols), ch = h / Float(rows)
        let amber = UIColor(red: 1, green: 0.75, blue: 0.4, alpha: 1)
        for i in 0..<cols {
            for j in 0..<rows {
                b.cyl(0.005, min(cw, ch) * 0.4, glow(amber),
                      at: [-w / 2 + cw * (Float(i) + 0.5), d + 0.003, -h / 2 + ch * (Float(j) + 0.5)])
            }
        }
    }

    static func profile(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        // Ellipsoidal "leko" pointing up: d is the barrel length
        b.box(w * 1.1, 0.02, 0.03, steel, at: [0, 0.01, 0])
        for sx: Float in [-1, 1] { b.box(0.015, d * 0.5, 0.03, steel, at: [sx * w * 0.55, d * 0.25, 0]) }
        b.box(w * 0.9, d * 0.35, w * 0.9, body, at: [0, d * 0.25, 0], corner: 0.03) // lamp house
        b.cyl(d * 0.65, w * 0.32, body, at: [0, d * 0.75, 0]) // barrel
        b.cyl(0.005, w * 0.25, glow(c), at: [0, d * 1.08, 0])
        b.cone(length: 6, radius: 0.6, beam(c, opacity: 0.16), apex: [0, d * 1.08, 0], direction: [0, 1, 0])
    }

    static func fresnel(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w * 1.1, 0.02, 0.03, steel, at: [0, 0.01, 0])
        for sx: Float in [-1, 1] { b.box(0.015, h * 0.6, 0.03, steel, at: [sx * w * 0.55, h * 0.3, 0]) }
        b.box(w * 0.9, d, w * 0.9, body, at: [0, h * 0.35 + d / 2, 0], corner: 0.04)
        b.cyl(0.005, w * 0.38, glow(c), at: [0, h * 0.35 + d + 0.003, 0])
        b.cone(length: 5, radius: 1.4, beam(c, opacity: 0.1), apex: [0, h * 0.35 + d, 0], direction: [0, 1, 0])
    }

    static func followspot(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        let top = h * 0.72
        for a in stride(from: Float(0), to: 2 * .pi, by: 2 * .pi / 3) {
            b.member([cos(a) * 0.45, 0, sin(a) * 0.45], [0, top - 0.1, 0], r: 0.015, steel)
        }
        b.cyl(0.12, 0.04, steel, at: [0, top - 0.04, 0])
        b.cyl(d, w * 0.38, body, at: [0, top + w * 0.3, 0], axis: [0, 0, -1])
        b.box(w * 0.8, w * 0.6, d * 0.3, body, at: [0, top + w * 0.3, d * 0.3], corner: 0.03)
        b.cyl(0.006, w * 0.3, glow(c), at: [0, top + w * 0.3, -d / 2 - 0.003], axis: [0, 0, 1])
        b.cone(length: 12, radius: 0.5, beam(c, opacity: 0.12), apex: [0, top + w * 0.3, -d / 2], direction: [0, -0.08, -1])
    }

    static func laser(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, h, d, body, at: [0, h / 2, 0], corner: 0.01)
        b.box(w * 0.3, h * 0.25, 0.004, glow(c), at: [0, h * 0.55, d / 2 + 0.002])
        for i in -3...3 {
            let a = Float(i) * 0.12
            b.member([0, h * 0.55, d / 2], [sin(a) * 8, h * 0.55 + 2.5, d / 2 + cos(a) * 8], r: 0.004, beam(c, opacity: 0.7))
        }
    }

    static func hazer(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h, d, bodyGrey, at: [0, h / 2, 0], corner: 0.02)
        b.cyl(0.06, 0.03, steel, at: [0, h * 0.6, d / 2 + 0.03], axis: [0, 0, 1])
        b.cone(length: 1.5, radius: 0.6, beam(.white, opacity: 0.12), apex: [0, h * 0.6, d / 2 + 0.06], direction: [0, 0.2, 1])
    }

    static func tube(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.cyl(w, h / 2, glow(c), at: [0, h / 2, 0], axis: [1, 0, 0])
        for sx: Float in [-1, 1] { b.cyl(0.03, h / 2 * 1.15, body, at: [sx * w / 2, h / 2, 0], axis: [1, 0, 0]) }
    }

    static func panel(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, d, h, body, at: [0, d / 2, 0], corner: 0.01)
        let n = 5
        let cw = w / Float(n), ch = h / Float(n)
        for i in 0..<n {
            for j in 0..<n {
                b.box(cw * 0.7, 0.004, ch * 0.7, glow(c), at: [-w / 2 + cw * (Float(i) + 0.5), d + 0.002, -h / 2 + ch * (Float(j) + 0.5)])
            }
        }
    }

    // MARK: - Audio

    @discardableResult
    static func speakerFront(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, at p: SIMD3<Float>, rot: simd_quatf? = nil) -> ModelEntity {
        let cab = b.box(w, h, d, body, at: p, corner: min(0.01, h * 0.05), rot: rot)
        b.box(w * 0.94, h * 0.86, 0.004, grille, at: [0, 0, d / 2 + 0.002], parent: cab)
        return cab
    }

    static func lineArray(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, count: Int, hung: Bool) {
        let n = max(1, count)
        if hung {
            // Flown hang under a bumper, with a progressive splay (J-shape).
            bumper(b, w * 1.02, 0.12, d * 1.1)
            var pos = SIMD3<Float>(0, 0, 0)
            var angle: Float = 0
            for i in 0..<n {
                angle += Float(i) * 0.012 + 0.01
                let rot = simd_quatf(angle: angle, axis: [1, 0, 0])
                pos += rot.act([0, -h, 0])
                speakerFront(b, w, h, d, at: pos + rot.act([0, h / 2, 0]), rot: rot)
            }
        } else {
            for i in 0..<n {
                speakerFront(b, w, h, d, at: [0, h / 2 + Float(i) * h, 0])
            }
        }
    }

    static func pointSource(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let cab = speakerFront(b, w, h, d, at: [0, h / 2, 0])
        b.cyl(0.004, min(w, h) * 0.32, bodyGrey, at: [0, -h * 0.12, d / 2 + 0.005], axis: [0, 0, 1], parent: cab)
        b.box(w * 0.5, h * 0.12, 0.006, bodyGrey, at: [0, h * 0.3, d / 2 + 0.005], parent: cab)
    }

    static func subwoofers(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, count: Int) {
        let n = max(1, count)
        for i in 0..<n {
            let x = (Float(i) - Float(n - 1) / 2) * (w + 0.02)
            let cab = b.box(w, h, d, body, at: [x, h / 2, 0], corner: 0.01)
            b.box(w * 0.95, h * 0.9, 0.004, grille, at: [0, 0, d / 2 + 0.002], parent: cab)
            let cones = w > h * 1.5 ? 2 : 1
            for k in 0..<cones {
                let cx = cones == 1 ? 0 : (Float(k) - 0.5) * w / 2
                b.cyl(0.006, min(h, w / Float(cones)) * 0.38, bodyGrey, at: [cx, 0, d / 2 + 0.006], axis: [0, 0, 1], parent: cab)
            }
        }
    }

    static func wedge(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        // Tilted cabinet facing the performer (towards -z / up).
        let rot = simd_quatf(angle: 0.75, axis: [1, 0, 0]) * simd_quatf(angle: .pi, axis: [0, 1, 0])
        speakerFront(b, w, h * 0.75, d * 0.8, at: [0, h * 0.42, 0], rot: rot)
    }

    static func column(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        speakerFront(b, w, h, d, at: [0, h / 2, 0])
    }

    static func rack(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, h, d, body, at: [0, h / 2 + 0.08, 0], corner: 0.015)
        let units = max(2, Int(h / 0.1))
        for i in 0..<units {
            let y = 0.08 + h * (Float(i) + 0.5) / Float(units)
            b.box(w * 0.85, h / Float(units) * 0.7, 0.004, bodyGrey, at: [0, y, d / 2 + 0.002])
            b.box(0.02, 0.008, 0.004, glow(i % 3 == 0 ? .systemGreen : c), at: [w * 0.35, y, d / 2 + 0.005])
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.cyl(0.03, 0.04, body, at: [sx * w * 0.4, 0.04, sz * d * 0.4], axis: [1, 0, 0])
        } }
    }

    static func microphone(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        if h < 0.2 { // kick-drum mic
            b.cyl(0.15, 0.025, body, at: [0, 0.05, 0], axis: [0, 0, 1])
            return
        }
        if w > 0.5 { // lectern
            b.box(w, h, d, wood, at: [0, h / 2, 0], corner: 0.02)
            b.member([0, h, 0], [0, h + 0.35, d * 0.3], r: 0.005, steel)
            b.sphere(0.02, body, at: [0, h + 0.35, d * 0.3])
            return
        }
        b.cyl(0.02, 0.14, body, at: [0, 0.01, 0])
        b.member([0, 0, 0], [0, h * 0.85, 0], r: 0.009, body)
        b.member([0, h * 0.85, 0], [0, h, 0.3], r: 0.007, body)
        b.cyl(0.16, 0.022, steel, at: [0, h, 0.38], axis: [0, -0.3, 1])
    }

    // MARK: - Video

    static func ledWall(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, h, d, body, at: [0, h / 2, 0])
        b.box(w * 0.995, h * 0.995, 0.004, glow(c.withAlphaComponent(1)), at: [0, h / 2, d / 2 + 0.002])
        // Cabinet seams every 0.5 m
        let cab: Float = 0.5
        let cols = Int((w / cab).rounded()), rows = Int((h / cab).rounded())
        if cols > 1 && cols <= 40 {
            for i in 1..<cols { b.box(0.004, h, 0.002, body, at: [-w / 2 + Float(i) * w / Float(cols), h / 2, d / 2 + 0.005]) }
        }
        if rows > 1 && rows <= 30 {
            for j in 1..<rows { b.box(w, 0.004, 0.002, body, at: [0, Float(j) * h / Float(rows), d / 2 + 0.005]) }
        }
    }

    static func projector(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        b.box(w, h, d, white, at: [0, h / 2, 0], corner: 0.03)
        b.cyl(0.12, h * 0.3, body, at: [w * 0.15, h / 2, -d / 2 - 0.06], axis: [0, 0, 1])
        b.cyl(0.004, h * 0.25, glow(.white), at: [w * 0.15, h / 2, -d / 2 - 0.122], axis: [0, 0, 1])
        b.cone(length: 10, radius: 2.5, beam(.white, opacity: 0.05), apex: [w * 0.15, h / 2, -d / 2 - 0.12], direction: [0, 0.05, -1])
    }

    static func camera(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        if d > 2 { // jib
            b.member([0, 0, 0], [0, h * 0.6, 0], r: 0.05, steel)
            b.member([0, h * 0.6, d * 0.25], [0, h, -d * 0.75], r: 0.04, steel)
            b.box(0.25, 0.25, 0.4, body, at: [0, h - 0.15, -d * 0.75])
            b.box(0.3, 0.3, 0.3, steel, at: [0, h * 0.6 - 0.1, d * 0.25])
            return
        }
        let top = h * 0.8
        for a in stride(from: Float(0), to: 2 * .pi, by: 2 * .pi / 3) {
            b.member([cos(a) * 0.5, 0, sin(a) * 0.5], [0, top - 0.1, 0], r: 0.014, steel)
        }
        b.box(0.18, 0.08, 0.18, body, at: [0, top - 0.05, 0])
        b.box(w * 0.5, 0.28, d * 0.6, bodyGrey, at: [0, top + 0.14, 0.05], corner: 0.02)
        b.cyl(d * 0.5, 0.07, body, at: [0, top + 0.12, -d * 0.45], axis: [0, 0, -1])
        b.box(0.18, 0.12, 0.05, body, at: [-w * 0.3, top + 0.3, 0.2])
        b.member([0.1, top, 0.2], [0.35, top - 0.05, 0.6], r: 0.012, body) // pan bar
    }

    static func ptz(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h * 0.3, d, white, at: [0, h * 0.15, 0], corner: 0.02)
        for sx: Float in [-1, 1] { b.box(w * 0.1, h * 0.5, d * 0.4, white, at: [sx * w * 0.38, h * 0.55, 0]) }
        b.sphere(w * 0.32, bodyGrey, at: [0, h * 0.62, 0])
        b.cyl(0.004, w * 0.15, glow(.systemBlue), at: [0, h * 0.62, -w * 0.32], axis: [0, 0, 1])
    }

    static func screen(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let legH: Float = 1.0
        b.box(w, h, 0.01, white, at: [0, legH + h / 2, 0])
        let f: Float = 0.04
        b.box(w + f * 2, f, f, alu, at: [0, legH + h + f / 2, 0])
        b.box(w + f * 2, f, f, alu, at: [0, legH - f / 2, 0])
        for sx: Float in [-1, 1] {
            b.box(f, h, f, alu, at: [sx * (w / 2 + f / 2), legH + h / 2, 0])
            b.member([sx * (w / 2 + f / 2), 0, 0], [sx * (w / 2 + f / 2), legH, 0], r: 0.02, alu)
            b.member([sx * (w / 2 + f / 2), 0, -0.8], [sx * (w / 2 + f / 2), legH + h * 0.5, 0], r: 0.015, alu)
        }
    }

    // MARK: - Truss

    static func boxTruss(_ b: Builder, length L: Float, size s: Float) {
        let r = max(0.012, s * 0.085)
        let half = s / 2 - r
        let corners: [SIMD2<Float>] = [[-half, -half], [half, -half], [half, half], [-half, half]] // (y,z) offsets
        for cnr in corners {
            b.member([-L / 2, s / 2 + cnr.x, cnr.y], [L / 2, s / 2 + cnr.x, cnr.y], r: r, alu)
        }
        let segs = max(1, Int((L / s).rounded()))
        let step = L / Float(segs)
        for f in 0..<4 {
            let a = corners[f], c = corners[(f + 1) % 4]
            for i in 0..<segs {
                let x0 = -L / 2 + Float(i) * step
                let (p, q) = i % 2 == 0 ? (a, c) : (c, a)
                b.member([x0, s / 2 + p.x, p.y], [x0 + step, s / 2 + q.x, q.y], r: r * 0.55, alu)
            }
        }
        // End frames
        for x in [-L / 2, L / 2] {
            for f in 0..<4 {
                let a = corners[f], c = corners[(f + 1) % 4]
                b.member([x, s / 2 + a.x, a.y], [x, s / 2 + c.x, c.y], r: r * 0.6, alu)
            }
        }
    }

    static func triTruss(_ b: Builder, length L: Float, size s: Float) {
        let r = max(0.012, s * 0.085)
        let th = s * 0.87
        let pts: [SIMD2<Float>] = [[r, -s / 2 + r], [r, s / 2 - r], [th - r, 0]] // (y,z)
        for p in pts { b.member([-L / 2, p.x, p.y], [L / 2, p.x, p.y], r: r, alu) }
        let segs = max(1, Int((L / s).rounded()))
        let step = L / Float(segs)
        for f in 0..<3 {
            let a = pts[f], c = pts[(f + 1) % 3]
            for i in 0..<segs {
                let x0 = -L / 2 + Float(i) * step
                let (p, q) = i % 2 == 0 ? (a, c) : (c, a)
                b.member([x0, p.x, p.y], [x0 + step, q.x, q.y], r: r * 0.55, alu)
            }
        }
    }

    static func ladderTruss(_ b: Builder, length L: Float, size s: Float) {
        let r = max(0.012, s * 0.085)
        for y in [r, s - r] { b.member([-L / 2, y, 0], [L / 2, y, 0], r: r, alu) }
        let segs = max(1, Int((L / s).rounded()))
        let step = L / Float(segs)
        for i in 0...segs {
            let x = -L / 2 + Float(i) * step
            b.member([x, r, 0], [x, s - r, 0], r: r * 0.55, alu)
            if i < segs {
                b.member([x, i % 2 == 0 ? r : s - r, 0], [x + step, i % 2 == 0 ? s - r : r, 0], r: r * 0.55, alu)
            }
        }
    }

    static func verticalTruss(_ b: Builder, height H: Float, size s: Float, at base: SIMD3<Float>) {
        let r = max(0.012, s * 0.085)
        let half = s / 2 - r
        let corners: [SIMD2<Float>] = [[-half, -half], [half, -half], [half, half], [-half, half]]
        for c in corners {
            b.member(base + [c.x, 0, c.y], base + [c.x, H, c.y], r: r, alu)
        }
        let segs = max(1, Int((H / s).rounded()))
        let step = H / Float(segs)
        for f in 0..<4 {
            let a = corners[f], c = corners[(f + 1) % 4]
            for i in 0..<segs {
                let y0 = Float(i) * step
                let (p, q) = i % 2 == 0 ? (a, c) : (c, a)
                b.member(base + [p.x, y0, p.y], base + [q.x, y0 + step, q.y], r: r * 0.55, alu)
            }
        }
    }

    static func tower(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let s = min(w, d) * 0.65
        b.box(w * 1.3, 0.02, d * 1.3, steel, at: [0, 0.01, 0])
        verticalTruss(b, height: h, size: s, at: [0, 0.02, 0])
        b.box(s * 1.35, 0.5, s * 1.35, steel, at: [0, h * 0.85, 0], corner: 0.01) // sleeve block
        b.box(s * 1.1, 0.15, s * 1.1, steel, at: [0, h + 0.08, 0]) // top section
    }

    static func roof(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, mobile: Bool, _ c: UIColor) {
        let s: Float = 0.39
        if mobile {
            let deckH: Float = 1.5
            deck(b, w, deckH, d, c)
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                verticalTruss(b, height: h - deckH, size: s, at: [sx * (w / 2 - s / 2), deckH, sz * (d / 2 - s / 2)])
            } }
            b.box(w, 0.05, d, canopy, at: [0, h + 0.35, 0])
            b.box(w, h - deckH, 0.02, canopy, at: [0, deckH + (h - deckH) / 2, -d / 2])
            return
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let p = SIMD3<Float>(sx * (w / 2 - s / 2), 0, sz * (d / 2 - s / 2))
            b.box(0.8, 0.02, 0.8, steel, at: p + [0, 0.01, 0])
            verticalTruss(b, height: h, size: s, at: p + [0, 0.02, 0])
        } }
        // Top grid (front, back, sides, middle)
        func span(_ e: Entity, at p: SIMD3<Float>, rotY: Float) {
            e.position = p
            e.orientation = simd_quatf(angle: rotY, axis: [0, 1, 0])
            b.root.addChild(e)
        }
        for z in [-d / 2 + s / 2, 0, d / 2 - s / 2] {
            let sb = Builder(); boxTruss(sb, length: w, size: s)
            span(sb.root, at: [0, h - s, z], rotY: 0)
        }
        for x in [-w / 2 + s / 2, w / 2 - s / 2] {
            let sb = Builder(); boxTruss(sb, length: d, size: s)
            span(sb.root, at: [x, h - s, 0], rotY: .pi / 2)
        }
        // Canopy (ridge roof)
        let slope = simd_quatf(angle: 0.12, axis: [1, 0, 0])
        b.box(w + 0.6, 0.03, d / 2 + 0.4, canopy, at: [0, h + 0.55, d / 4], rot: slope)
        b.box(w + 0.6, 0.03, d / 2 + 0.4, canopy, at: [0, h + 0.55, -d / 4], rot: slope.inverse)
    }

    // MARK: - Rigging

    static func hoist(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h * 0.6, d * 0.8, body, at: [0, h * 0.5, 0], corner: 0.03)
        b.cyl(w * 0.9, h * 0.15, body, at: [0, h * 0.5, 0], axis: [1, 0, 0])
        b.member([0, h * 0.8, 0], [0, h + 1.2, 0], r: 0.008, steel) // chain to the grid
        b.box(0.04, 0.12, 0.02, yellow, at: [0, h * 0.1, 0]) // hook
        b.box(w * 0.4, h * 0.25, d * 0.6, steel, at: [w * 0.55, h * 0.4, 0]) // chain bag
    }

    static func bumper(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h * 0.4, 0.04, body, at: [0, h * 0.3, d / 2])
        b.box(w, h * 0.4, 0.04, body, at: [0, h * 0.3, -d / 2])
        for sx: Float in [-1, 1] { b.box(0.04, h * 0.4, d, body, at: [sx * w / 2, h * 0.3, 0]) }
        b.box(0.04, h * 0.4, d, body, at: [0, h * 0.3, 0])
        b.member([0, h * 0.5, 0], [0, h + 1.0, 0], r: 0.008, steel)
    }

    // MARK: - Staging

    static func deck(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        let top: Float = min(0.05, h)
        b.box(w, top, d, deckTop, at: [0, h - top / 2, 0])
        let legH = h - top
        if legH > 0.01 {
            // Skirting on all four sides
            b.box(w, legH, 0.01, skirt, at: [0, legH / 2, d / 2 - 0.005])
            b.box(w, legH, 0.01, skirt, at: [0, legH / 2, -d / 2 + 0.005])
            b.box(0.01, legH, d, skirt, at: [w / 2 - 0.005, legH / 2, 0])
            b.box(0.01, legH, d, skirt, at: [-w / 2 + 0.005, legH / 2, 0])
        }
        // LED nosing on the front edge (uses the element colour)
        b.box(w, 0.012, 0.012, glow(c), at: [0, h - 0.006, d / 2 + 0.006])
        // Deck seams every 2×1 m
        if w > 2.1 { for i in 1..<Int(w / 2) { b.box(0.006, 0.002, d, body, at: [-w / 2 + Float(i) * 2, h + 0.001, 0]) } }
        if d > 1.1 { for j in 1..<Int(d) { b.box(w, 0.002, 0.006, body, at: [0, h + 0.001, -d / 2 + Float(j)]) } }
    }

    static func stairs(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let steps = max(1, Int((h / 0.2).rounded(.up)))
        let rise = h / Float(steps), run = d / Float(steps)
        for i in 0..<steps {
            let y = rise * Float(i + 1)
            b.box(w, y, run, deckTop, at: [0, y / 2, d / 2 - run * (Float(i) + 0.5)])
        }
        for sx: Float in [-1, 1] {
            b.member([sx * w / 2, 0.9, d / 2], [sx * w / 2, h + 0.9, -d / 2], r: 0.02, alu)
            b.member([sx * w / 2, 0, d / 2], [sx * w / 2, 0.9, d / 2], r: 0.02, alu)
            b.member([sx * w / 2, h, -d / 2], [sx * w / 2, h + 0.9, -d / 2], r: 0.02, alu)
        }
    }

    static func riser(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        let wheel: Float = 0.1
        deck(b, w, h, d, c)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.cyl(0.04, wheel / 2, body, at: [sx * (w / 2 - 0.15), wheel / 2, sz * (d / 2 - 0.15)], axis: [1, 0, 0])
        } }
    }

    static func barrier(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        if d < 0.7 { // Vauban / Heras: simple fence
            b.box(w, 0.04, 0.04, steel, at: [0, h - 0.02, 0])
            b.box(w, 0.04, 0.04, steel, at: [0, 0.1, 0])
            let bars = max(2, Int(w / 0.12))
            for i in 0...bars { b.member([-w / 2 + Float(i) * w / Float(bars), 0.1, 0], [-w / 2 + Float(i) * w / Float(bars), h, 0], r: 0.008, steel) }
            for sx: Float in [-1, 1] { b.box(0.1, 0.05, d, steel, at: [sx * w * 0.45, 0.025, 0]) }
            return
        }
        // Crash barrier: foot plate on the audience side, front wall, brace
        b.box(w, 0.02, d, alu, at: [0, 0.01, 0])
        b.box(w, h, 0.04, alu, at: [0, h / 2, -d / 2 + 0.02])
        b.box(w, 0.08, 0.15, alu, at: [0, h, -d / 2 + 0.05])
        for sx: Float in [-0.45, 0.45] {
            b.member([sx * w, 0.02, d / 2 - 0.05], [sx * w, h * 0.9, -d / 2 + 0.04], r: 0.025, alu)
        }
    }

    // MARK: - SFX

    static func jet(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, plume: UIColor, opacity: Float) {
        b.box(w, h, d, body, at: [0, h / 2, 0], corner: 0.02)
        b.cyl(0.08, w * 0.15, steel, at: [0, h + 0.04, 0])
        b.cone(length: 3.5, radius: 0.35, beam(plume, opacity: opacity), apex: [0, h + 0.08, 0], direction: [0, 1, 0])
    }

    static func confetti(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        if w < 0.15 { // hand-held tube
            b.cyl(h, w / 2, pbr(c, rough: 0.6, metal: 0.2), at: [0, h / 2, 0])
            return
        }
        b.box(w, h * 0.3, d, body, at: [0, h * 0.15, 0], corner: 0.02)
        b.cyl(h * 0.8, w * 0.25, steel, at: [0, h * 0.6, 0.05], axis: [0, 1, 0.3])
    }

    // MARK: - Control & power

    static func console(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor, lighting: Bool) {
        let deskH: Float = 0.8
        // Stand / table
        b.box(w * 1.05, 0.04, d * 1.05, body, at: [0, deskH - 0.02, 0])
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.box(0.04, deskH - 0.04, 0.04, body, at: [sx * w * 0.48, (deskH - 0.04) / 2, sz * d * 0.45])
        } }
        // Console surface (tilted)
        let tilt = simd_quatf(angle: 0.12, axis: [1, 0, 0])
        let surf = b.box(w, h * 0.3, d, bodyGrey, at: [0, deskH + h * 0.15, 0], corner: 0.02, rot: tilt)
        // Fader rows / encoders
        let strips = max(4, Int(w / (lighting ? 0.09 : 0.04)))
        for i in 0..<strips {
            let x = -w * 0.45 + w * 0.9 * (Float(i) + 0.5) / Float(strips)
            b.box(w * 0.9 / Float(strips) * 0.4, 0.004, d * 0.35, body, at: [x, h * 0.15 + 0.002, d * 0.2], parent: surf)
            b.box(0.012, 0.01, 0.02, glow(i % 8 == 0 ? .systemRed : c), at: [x, h * 0.15 + 0.006, d * 0.3 - Float(i % 5) * 0.025], parent: surf)
        }
        // Screens
        let screens = max(1, Int(w / (lighting ? 0.45 : 0.6)))
        for i in 0..<screens {
            let x = -w * 0.45 + w * 0.9 * (Float(i) + 0.5) / Float(screens)
            let rot = simd_quatf(angle: -0.3, axis: [1, 0, 0])
            let scr = b.box(w * 0.9 / Float(screens) * 0.92, h * 0.85, 0.03, body, at: [x, deskH + h * 0.5 + 0.1, -d * 0.4], rot: rot)
            b.box(w * 0.9 / Float(screens) * 0.85, h * 0.75, 0.002, glow(UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1)), at: [0, 0, 0.017], parent: scr)
        }
    }

    static func distro(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h, d, bodyGrey, at: [0, h / 2 + 0.06, 0], corner: 0.01)
        let n = max(2, Int(w / 0.1))
        for i in 0..<n {
            let x = -w * 0.4 + w * 0.8 * Float(i) / Float(max(1, n - 1))
            b.cyl(0.03, 0.025, i % 3 == 0 ? red : yellow, at: [x, h * 0.4, d / 2 + 0.015], axis: [0, 0, 1])
        }
        b.box(w * 0.6, h * 0.25, 0.005, body, at: [0, h * 0.75, d / 2 + 0.003])
        for sx: Float in [-1, 1] { b.cyl(0.03, 0.04, body, at: [sx * w * 0.35, 0.04, 0], axis: [1, 0, 0]) }
    }

    static func generator(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h, d, pbr(UIColor(red: 0.85, green: 0.85, blue: 0.82, alpha: 1), rough: 0.5, metal: 0.3), at: [0, h / 2, 0], corner: 0.03)
        let vents = max(2, Int(w / 0.5))
        for i in 0..<vents {
            b.box(w / Float(vents) * 0.6, h * 0.5, 0.01, body, at: [-w / 2 + w * (Float(i) + 0.5) / Float(vents), h * 0.55, d / 2 + 0.005])
        }
        b.cyl(0.5, 0.08, steel, at: [w * 0.35, h + 0.25, 0])
    }

    static func ramp(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, h, d * 0.5, yellow, at: [0, h / 2, 0])
        b.box(w, h * 0.5, d * 0.25, body, at: [0, h * 0.25, d * 0.37])
        b.box(w, h * 0.5, d * 0.25, body, at: [0, h * 0.25, -d * 0.37])
    }

    // MARK: - Backline & venue

    static func drums(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, _ c: UIColor) {
        let shell = pbr(c, rough: 0.2, metal: 0.4)
        let brass = pbr(UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1), rough: 0.25, metal: 1)
        b.cyl(0.45, 0.28, shell, at: [0, 0.28, 0.3], axis: [0, 0, 1])                       // kick
        b.cyl(0.004, 0.27, white, at: [0, 0.28, 0.53], axis: [0, 0, 1])
        b.cyl(0.15, 0.18, shell, at: [-0.4, 0.62, 0.15]) ; b.member([-0.4, 0, 0.15], [-0.4, 0.55, 0.15], r: 0.01, steel) // snare
        b.cyl(0.2, 0.13, shell, at: [-0.12, 0.75, 0.25], axis: [0, 0.7, 0.7])                // rack toms
        b.cyl(0.2, 0.15, shell, at: [0.15, 0.75, 0.25], axis: [0, 0.7, 0.7])
        b.cyl(0.4, 0.2, shell, at: [0.5, 0.4, 0]) ; b.member([0.5, 0, 0], [0.5, 0.2, 0], r: 0.01, steel) // floor tom
        let cymbals: [SIMD4<Float>] = [[-0.7, 1.0, 0.1, 0.18], [-0.45, 1.35, 0.35, 0.24], [0.55, 1.4, 0.35, 0.28], [0.8, 1.1, 0.1, 0.25]]
        for cy in cymbals {
            b.member([cy.x, 0, cy.z], [cy.x, cy.y, cy.z], r: 0.008, steel)
            b.cyl(0.004, cy.w, brass, at: [cy.x, cy.y, cy.z])
        }
        b.cyl(0.08, 0.18, body, at: [0, 0.55, -0.45]); b.member([0, 0, -0.45], [0, 0.5, -0.45], r: 0.02, steel) // throne
        _ = w; _ = h; _ = d
    }

    static func ampStack(_ b: Builder, _ w: Float, _ h: Float, _ d: Float, bass: Bool) {
        let headH: Float = min(0.28, h * 0.3)
        let cabs = h > 1.4 ? 2 : 1
        let cabH = (h - headH) / Float(cabs)
        for i in 0..<cabs {
            let cab = b.box(w, cabH, d, tolex, at: [0, cabH * (Float(i) + 0.5), 0], corner: 0.015)
            b.box(w * 0.88, cabH * 0.85, 0.004, bass ? grille : cloth, at: [0, 0, d / 2 + 0.002], parent: cab)
        }
        if h >= 0.6 {
            let head = b.box(w, headH, d * 0.8, tolex, at: [0, h - headH / 2, -d * 0.05], corner: 0.015)
            b.box(w * 0.85, headH * 0.35, 0.004, pbr(UIColor(red: 0.8, green: 0.65, blue: 0.3, alpha: 1), rough: 0.3, metal: 1),
                  at: [0, -headH * 0.15, d * 0.4 + 0.002], parent: head)
        }
    }

    static func piano(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let bodyY = h * 0.65
        if d < 1.0 { // organ / upright
            b.box(w, h, d, wood, at: [0, h / 2, 0], corner: 0.02)
            b.box(w * 0.9, 0.04, 0.25, white, at: [0, h * 0.7, d / 2 + 0.1])
            return
        }
        b.box(w, h * 0.3, d, pianoBlack, at: [0, bodyY, 0], corner: 0.1)
        b.box(w * 0.98, 0.02, d * 0.95, pianoBlack, at: [0.15, bodyY + h * 0.35, -0.05], rot: simd_quatf(angle: 0.6, axis: [0, 0, 1]))
        b.box(w * 0.95, 0.03, 0.18, white, at: [0, bodyY + h * 0.05, d / 2 + 0.07])
        for (x, z) in [(-w * 0.4, d * 0.4), (w * 0.4, d * 0.4), (0, -d * 0.4)] {
            b.box(0.08, bodyY - h * 0.15, 0.08, pianoBlack, at: [x, (bodyY - h * 0.15) / 2, z])
        }
    }

    static func keyboard(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.member([-w * 0.3, 0, -0.25], [w * 0.3, h - 0.08, 0.2], r: 0.015, steel)
        b.member([-w * 0.3, 0, 0.25], [w * 0.3, h - 0.08, -0.2], r: 0.015, steel)
        b.member([w * 0.3, 0, -0.25], [-w * 0.3, h - 0.08, 0.2], r: 0.015, steel)
        b.member([w * 0.3, 0, 0.25], [-w * 0.3, h - 0.08, -0.2], r: 0.015, steel)
        let kb = b.box(w, 0.12, d, pbr(.systemRed, rough: 0.4, metal: 0.2), at: [0, h - 0.04, 0], corner: 0.01)
        b.box(w * 0.85, 0.01, d * 0.45, white, at: [0, 0.06, d * 0.2], parent: kb)
    }

    static func roadCase(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let wheel: Float = 0.1
        b.box(w, h - wheel, d, body, at: [0, wheel + (h - wheel) / 2, 0], corner: 0.01)
        for y in [wheel + 0.01, h - 0.01, wheel + (h - wheel) * 0.6] {
            b.box(w + 0.01, 0.02, d + 0.01, alu, at: [0, y, 0])
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.cyl(0.05, wheel / 2, body, at: [sx * (w / 2 - 0.08), wheel / 2, sz * (d / 2 - 0.08)], axis: [1, 0, 0])
        } }
    }

    static func table(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        b.box(w, 0.04, d, pbr(UIColor(white: 0.15, alpha: 1), rough: 0.5, metal: 0.1), at: [0, h - 0.02, 0], corner: 0.01)
        if w < 1.0 && d < 1.0 { // high table
            b.member([0, 0, 0], [0, h - 0.04, 0], r: 0.03, steel)
            b.cyl(0.02, 0.25, steel, at: [0, 0.01, 0])
            return
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.member([sx * (w / 2 - 0.05), 0, sz * (d / 2 - 0.05)], [sx * (w / 2 - 0.05), h - 0.04, sz * (d / 2 - 0.05)], r: 0.018, steel)
        } }
    }

    static func chair(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let seat: Float = min(0.47, h * 0.75)
        b.box(w, 0.05, d, bodyGrey, at: [0, seat, 0], corner: 0.02)
        if h > seat + 0.1 {
            b.box(w, h - seat, 0.04, bodyGrey, at: [0, seat + (h - seat) / 2, -d / 2 + 0.02], corner: 0.02)
        }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.member([sx * (w / 2 - 0.03), 0, sz * (d / 2 - 0.03)], [sx * (w / 2 - 0.03), seat, sz * (d / 2 - 0.03)], r: 0.012, steel)
        } }
    }

    static func tent(_ b: Builder, _ w: Float, _ h: Float, _ d: Float) {
        let eave = h * 0.75
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            b.member([sx * w / 2, 0, sz * d / 2], [sx * w / 2, eave, sz * d / 2], r: 0.025, alu)
        } }
        let tilt: Float = atan2(h - eave, d / 2)
        let half = sqrtf(powf(d / 2, 2) + powf(h - eave, 2))
        b.box(w, 0.02, half, canopy, at: [0, (eave + h) / 2, d / 4], rot: simd_quatf(angle: tilt, axis: [1, 0, 0]))
        b.box(w, 0.02, half, canopy, at: [0, (eave + h) / 2, -d / 4], rot: simd_quatf(angle: -tilt, axis: [1, 0, 0]))
    }
}
