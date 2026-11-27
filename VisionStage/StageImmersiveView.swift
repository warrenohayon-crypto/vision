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

    var body: some View {
        RealityView { content in
            // Ground plane reference
            let floor = ModelEntity(
                mesh: .generatePlane(width: 12, depth: 12),
                materials: [SimpleMaterial(color: .init(white: 0.15, alpha: 0.5), isMetallic: false)]
            )
            floor.position = SIMD3<Float>(0, -0.01, -3)
            content.add(floor)

            // Grid lines
            for i in stride(from: -6, through: 6, by: 1) {
                let line = ModelEntity(
                    mesh: .generateBox(width: 0.01, height: 0.001, depth: 12),
                    materials: [SimpleMaterial(color: .init(white: 0.3, alpha: 0.6), isMetallic: false)]
                )
                line.position = SIMD3<Float>(Float(i), 0, -3)
                content.add(line)

                let line2 = ModelEntity(
                    mesh: .generateBox(width: 12, height: 0.001, depth: 0.01),
                    materials: [SimpleMaterial(color: .init(white: 0.3, alpha: 0.6), isMetallic: false)]
                )
                line2.position = SIMD3<Float>(0, 0, Float(i) - 3)
                content.add(line2)
            }

        } update: { content in
            // Remove old stage elements (tagged)
            content.entities
                .filter { $0.name.hasPrefix("stage_") }
                .forEach { content.remove($0) }

            // Re-add all elements
            for element in model.elements where element.isActive {
                let entity = makeEntity(for: element)
                content.add(entity)
            }
        }
    }

    func makeEntity(for element: StageElement) -> ModelEntity {
        let mesh: MeshResource
        switch element.type {
        case .mainStage:
            mesh = .generateBox(width: 3.0 * element.scale,
                                height: 0.3 * element.scale,
                                depth: 2.0 * element.scale)
        case .screen:
            mesh = .generateBox(width: 1.8 * element.scale,
                                height: 1.0 * element.scale,
                                depth: 0.05 * element.scale)
        case .lighting:
            mesh = .generateSphere(radius: 0.15 * element.scale)
        case .speaker:
            mesh = .generateBox(width: 0.4 * element.scale,
                                height: 0.8 * element.scale,
                                depth: 0.4 * element.scale)
        case .camera:
            mesh = .generateBox(width: 0.2 * element.scale,
                                height: 0.2 * element.scale,
                                depth: 0.35 * element.scale)
        case .truss:
            mesh = .generateBox(width: 0.15 * element.scale,
                                height: 3.0 * element.scale,
                                depth: 0.15 * element.scale)
        case .table:
            mesh = .generateBox(width: 1.5 * element.scale,
                                height: 0.05 * element.scale,
                                depth: 0.7 * element.scale)
        case .chair:
            mesh = .generateBox(width: 0.5 * element.scale,
                                height: 0.5 * element.scale,
                                depth: 0.5 * element.scale)
        }

        let uiColor: UIColor
        switch element.color {
        case .blue:   uiColor = .systemBlue
        case .red:    uiColor = .systemRed
        case .green:  uiColor = .systemGreen
        case .yellow: uiColor = .systemYellow
        case .purple: uiColor = .systemPurple
        case .white:  uiColor = .white
        case .orange: uiColor = .systemOrange
        }

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: uiColor)
        material.roughness = .init(floatLiteral: 0.4)
        material.metallic  = .init(floatLiteral: 0.3)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "stage_\(element.id)"
        entity.position = element.position
        entity.transform.rotation = simd_quatf(angle: element.rotation * .pi / 180,
                                               axis: SIMD3<Float>(0, 1, 0))

        // Label above element
        let label = ModelEntity(
            mesh: .generateText(element.name,
                                extrusionDepth: 0.001,
                                font: .systemFont(ofSize: 0.08),
                                alignment: .center),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        label.position = SIMD3<Float>(0, 0.4 * element.scale + 0.2, 0)
        entity.addChild(label)

        // Tap/hover interaction
        entity.components.set(HoverEffectComponent())
        entity.generateCollisionShapes(recursive: false)
        entity.components.set(InputTargetComponent())

        return entity
    }
}
