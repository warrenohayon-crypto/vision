//
//  StageImmersiveView.swift
//  VisionStage
//

import SwiftUI
import RealityKit
import UIKit

// MARK: - 3D Immersive View

struct StageImmersiveView: View {
    @EnvironmentObject var model: StageViewModel
    @State private var scene = SceneCache()

    var body: some View {
        RealityView { content in
            content.add(scene.root)
            scene.root.addChild(makeFloor())
            scene.sync(with: model.elements)
        } update: { _ in
            scene.sync(with: model.elements)
        }
        // Tap an element to select it in the control panel.
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            if let id = scene.elementID(for: value.entity) {
                model.selectedElement = model.elements.first { $0.id == id }
            }
        })
        // Drag an element across the floor to move it.
        .gesture(DragGesture().targetedToAnyEntity().onChanged { value in
            guard let id = scene.elementID(for: value.entity),
                  var element = model.elements.first(where: { $0.id == id }) else { return }
            let p = value.convert(value.location3D, from: .local, to: scene.root)
            element.position.x = (p.x * 10).rounded() / 10
            element.position.z = (p.z * 10).rounded() / 10
            model.updateElement(element)
            if model.selectedElement?.id == id { model.selectedElement = element }
        })
    }

    private func makeFloor() -> Entity {
        let floor = Entity()
        let plane = ModelEntity(
            mesh: .generatePlane(width: 30, depth: 30),
            materials: [SimpleMaterial(color: .init(white: 0.12, alpha: 0.45), isMetallic: false)]
        )
        plane.position = [0, -0.01, -6]
        floor.addChild(plane)
        let lineMat = SimpleMaterial(color: .init(white: 0.35, alpha: 0.5), isMetallic: false)
        for i in stride(from: -15, through: 15, by: 1) {
            let a = ModelEntity(mesh: .generateBox(width: 0.01, height: 0.001, depth: 30), materials: [lineMat])
            a.position = [Float(i), 0, -6]
            floor.addChild(a)
            let b = ModelEntity(mesh: .generateBox(width: 30, height: 0.001, depth: 0.01), materials: [lineMat])
            b.position = [0, 0, Float(i) - 6]
            floor.addChild(b)
        }
        return floor
    }
}

// MARK: - Scene cache

/// Keeps one entity per stage element and only rebuilds an element's model
/// when something that changes its geometry changes (moving it just updates
/// the transform), so big rigs stay smooth while you edit them.
@MainActor
final class SceneCache {
    let root = Entity()
    private var entries: [UUID: (signature: String, entity: Entity)] = [:]

    func elementID(for entity: Entity) -> UUID? {
        var e: Entity? = entity
        while let current = e {
            if current.name.hasPrefix("stage_"), let id = UUID(uuidString: String(current.name.dropFirst(6))) {
                return id
            }
            e = current.parent
        }
        return nil
    }

    func sync(with elements: [StageElement]) {
        let visible = elements.filter(\.isActive)
        let ids = Set(visible.map(\.id))
        for (id, entry) in entries where !ids.contains(id) {
            entry.entity.removeFromParent()
            entries[id] = nil
        }
        for element in visible {
            let sig = signature(of: element)
            let entity: Entity
            if let entry = entries[element.id], entry.signature == sig {
                entity = entry.entity
            } else {
                entries[element.id]?.entity.removeFromParent()
                entity = StageEntityBuilder.makeEntity(for: element)
                root.addChild(entity)
                entries[element.id] = (sig, entity)
            }
            entity.position = element.position
            entity.orientation = simd_quatf(angle: element.rotation * .pi / 180, axis: [0, 1, 0])
        }
    }

    private func signature(of e: StageElement) -> String {
        "\(e.productID ?? e.type.rawValue)|\(e.name)|\(e.scale)|\(e.color.rawValue)|\(e.quantity)|\(e.position.y > StageEntityBuilder.hangHeight)"
    }
}

// MARK: - Entity builder

enum StageEntityBuilder {
    /// Elements placed above this height are treated as flown / hung.
    static let hangHeight: Float = 2.5

    static func spec(for element: StageElement) -> ModelSpec {
        let accent = element.color.uiColor
        var spec: ModelSpec
        if let p = element.product {
            spec = ModelSpec(shape: p.shape, width: p.width, height: p.height, depth: p.depth, accent: accent)
        } else {
            spec = ProductModelFactory.defaultSpec(for: element.type, accent: accent)
        }
        spec.quantity = element.quantity
        spec.elevated = element.position.y > hangHeight
        return spec
    }

    static func makeEntity(for element: StageElement) -> Entity {
        let spec = spec(for: element)
        let container = Entity()
        container.name = "stage_\(element.id.uuidString)"

        let model = ProductModelFactory.makeModel(spec)
        model.scale = SIMD3(repeating: element.scale)
        // Hang light fixtures upside-down under the rig.
        if spec.elevated && element.type == .lighting && spec.shape != .followspot {
            model.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        }
        container.addChild(model)

        // Collision box around the visible geometry (beams excluded would be
        // nicer, but bounds keep the hit target generous and cheap).
        let bounds = model.visualBounds(relativeTo: container)
        let hasBeam = element.type == .lighting || element.type == .sfx
        let size = hasBeam
            ? SIMD3(spec.width, spec.height, spec.depth) * element.scale
            : bounds.extents
        let hitSize = simd_clamp(size, SIMD3(repeating: 0.15), SIMD3(30, 12, 30))
        container.components.set(CollisionComponent(shapes: [
            .generateBox(size: hitSize).offsetBy(translation: hitCenter(bounds, element: element, spec: spec))
        ]))
        container.components.set(InputTargetComponent())
        container.components.set(HoverEffectComponent())

        // Label above the element
        let label = ModelEntity(
            mesh: .generateText(element.name, extrusionDepth: 0.001,
                                font: .systemFont(ofSize: 0.07), alignment: .center),
            materials: [UnlitMaterial(color: .white)]
        )
        let lb = label.visualBounds(relativeTo: nil)
        let topY = spec.elevated && element.type == .lighting ? 0.15 : min(bounds.max.y, spec.height * element.scale + 0.3) + 0.12
        label.position = [-lb.center.x, topY, 0]
        container.addChild(label)
        return container
    }

    /// Keep the hit box on the physical object, not on long light beams.
    private static func hitCenter(_ bounds: BoundingBox, element: StageElement, spec: ModelSpec) -> SIMD3<Float> {
        if element.type == .lighting || element.type == .sfx {
            let h = spec.height * element.scale
            return spec.elevated ? [0, -h / 2, 0] : [0, h / 2, 0]
        }
        return bounds.center
    }
}
