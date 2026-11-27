//
//  StageModels.swift
//  VisionStage
//

import SwiftUI

// MARK: - Data Models

struct StageElement: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: ElementType
    var position: SIMD3<Float>
    var rotation: Float       // Y-axis rotation in degrees
    var scale: Float
    var color: ElementColor
    var isActive: Bool
    var notes: String

    enum ElementType: String, Codable, CaseIterable {
        case mainStage    = "Scène principale"
        case screen       = "Écran LED"
        case lighting     = "Éclairage"
        case speaker      = "Enceinte"
        case camera       = "Caméra"
        case truss        = "Structure / Truss"
        case table        = "Table technique"
        case chair        = "Chaise / Siège"

        var icon: String {
            switch self {
            case .mainStage:  return "theatermasks.fill"
            case .screen:     return "rectangle.fill.on.rectangle.fill"
            case .lighting:   return "lightbulb.fill"
            case .speaker:    return "speaker.wave.3.fill"
            case .camera:     return "camera.fill"
            case .truss:      return "square.3.layers.3d"
            case .table:      return "rectangle.fill"
            case .chair:      return "chair.lounge.fill"
            }
        }
    }

    enum ElementColor: String, Codable, CaseIterable {
        case blue   = "Bleu"
        case red    = "Rouge"
        case green  = "Vert"
        case yellow = "Jaune"
        case purple = "Violet"
        case white  = "Blanc"
        case orange = "Orange"

        var swiftUIColor: Color {
            switch self {
            case .blue:   return .blue
            case .red:    return .red
            case .green:  return .green
            case .yellow: return .yellow
            case .purple: return .purple
            case .white:  return .white
            case .orange: return .orange
            }
        }
    }
}

struct EventInfo: Codable {
    var name: String = "Nouvel Événement"
    var date: Date = Date()
    var venue: String = ""
    var capacity: Int = 0
    var notes: String = ""
}
