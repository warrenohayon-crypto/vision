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

    func loadDefaultStage() {
        elements = [
            StageElement(name: "Scène principale", type: .mainStage,
                         position: SIMD3<Float>(0, 0, -3), rotation: 0, scale: 1.0,
                         color: .blue, isActive: true, notes: "Scène centrale"),
            StageElement(name: "Écran LED gauche", type: .screen,
                         position: SIMD3<Float>(-2, 1, -3), rotation: 0, scale: 0.8,
                         color: .white, isActive: true, notes: ""),
            StageElement(name: "Écran LED droit", type: .screen,
                         position: SIMD3<Float>(2, 1, -3), rotation: 0, scale: 0.8,
                         color: .white, isActive: true, notes: ""),
            StageElement(name: "Éclairage principal", type: .lighting,
                         position: SIMD3<Float>(0, 2.5, -3), rotation: 0, scale: 0.6,
                         color: .yellow, isActive: true, notes: "Spots principaux"),
            StageElement(name: "Enceinte gauche", type: .speaker,
                         position: SIMD3<Float>(-3, 0.5, -2.5), rotation: 15, scale: 0.5,
                         color: .orange, isActive: true, notes: "Line array"),
            StageElement(name: "Enceinte droite", type: .speaker,
                         position: SIMD3<Float>(3, 0.5, -2.5), rotation: -15, scale: 0.5,
                         color: .orange, isActive: true, notes: "Line array"),
        ]
    }

    func addElement(_ element: StageElement) {
        elements.append(element)
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
