//
//  LibraryModels.swift
//  VisionStage
//
//  Data model for the production-element library (catalog of real-world
//  stages, lights, sound, video, truss, rigging, SFX, power, backline...).
//

import Foundation

// MARK: - Category

enum LibraryCategory: String, CaseIterable, Identifiable, Codable {
    case staging   = "Scènes & Praticables"
    case lighting  = "Lumière"
    case audio     = "Son"
    case video     = "Vidéo & LED"
    case truss     = "Truss & Structures"
    case rigging   = "Levage & Rigging"
    case sfx       = "Effets spéciaux"
    case control   = "Régie & Consoles"
    case power     = "Énergie & Distribution"
    case backline  = "Backline"
    case venue     = "Mobilier & Sécurité"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .staging:  return "theatermasks.fill"
        case .lighting: return "lightbulb.fill"
        case .audio:    return "speaker.wave.3.fill"
        case .video:    return "tv.fill"
        case .truss:    return "square.3.layers.3d"
        case .rigging:  return "link"
        case .sfx:      return "flame.fill"
        case .control:  return "slider.horizontal.3"
        case .power:    return "bolt.fill"
        case .backline: return "guitars.fill"
        case .venue:    return "chair.lounge.fill"
        }
    }

    /// Which element type a product of this category becomes on stage.
    var elementType: StageElement.ElementType {
        switch self {
        case .staging:  return .mainStage
        case .lighting: return .lighting
        case .audio:    return .speaker
        case .video:    return .screen
        case .truss:    return .truss
        case .rigging:  return .rigging
        case .sfx:      return .sfx
        case .control:  return .control
        case .power:    return .power
        case .backline: return .backline
        case .venue:    return .table
        }
    }
}

// MARK: - 3D shape family

/// The procedural 3D model used to draw a product. Each shape is built from
/// the product's real dimensions, so a MegaPointe and a LEDBeam 150 share the
/// moving-head look but have different sizes.
enum ProductShape: String, Codable {
    // Lighting
    case movingHead, movingHeadWash, movingBar, parCan, ledPar, ledBatten, strobe,
         blinder, profileSpot, fresnel, followspot, laser, hazer, tube, panel
    // Audio
    case lineArrayBox, pointSource, subwoofer, wedge, columnSpeaker, ampRack, microphone
    // Video
    case ledPanel, projector, camera, ptzCamera, projectionScreen, mediaServer
    // Structure
    case boxTruss, triangleTruss, ladderTruss, trussTower, cornerBlock, basePlate,
         roofSystem, mobileStage
    // Rigging
    case chainHoist, bumper, spanset
    // Staging
    case stageDeck, stairs, rollingRiser, barrier
    // SFX
    case sfxJet, sparkular, confettiCannon, flameUnit
    // Control / power
    case mixingConsole, lightingConsole, distroBox, generator, cableRamp
    // Backline / venue
    case drumKit, guitarAmp, bassAmp, piano, keyboardStand, roadCase, table, chair, tent
}

// MARK: - Product

struct LibraryProduct: Identifiable, Hashable {
    /// Stable id, e.g. "robe-megapointe".
    let id: String
    let brand: String
    let model: String
    let category: LibraryCategory
    /// Finer grouping inside a category (e.g. "Spot / Beam", "Line array").
    let family: String
    let shape: ProductShape
    /// Approximate overall size in meters (width, height, depth).
    let width: Float
    let height: Float
    let depth: Float
    /// Approximate weight in kg (0 = unknown).
    let weight: Float
    /// Approximate power draw in watts (0 = unknown / passive).
    let power: Int
    let specs: String

    var elementType: StageElement.ElementType {
        switch shape {
        case .camera, .ptzCamera: return .camera
        case .chair:              return .chair
        default:                  return category.elementType
        }
    }

    var displayName: String { brand == "Générique" ? model : "\(brand) \(model)" }

    var dimensionText: String {
        String(format: "%.2f × %.2f × %.2f m", width, height, depth)
    }
}
