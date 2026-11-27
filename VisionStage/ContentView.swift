//
//  ContentView.swift
//  VisionStage
//
//  Created by Warren Ohayon on 05/03/2026.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Hello, world!")

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
import SwiftUI

// MARK: - App Entry Point
@main
struct StageVisionApp: App {
@StateObject private var stageModel = StageViewModel()

```
var body: some Scene {
    // Main 2D window (control panel)
    WindowGroup("Stage Vision", id: "main") {
        ContentView()
            .environmentObject(stageModel)
    }
    .windowStyle(.plain)
    .defaultSize(width: 900, height: 600)

    // 3D immersive space for the stage
    ImmersiveSpace(id: "StageSpace") {
        StageImmersiveView()
            .environmentObject(stageModel)
    }
    .immersionStyle(selection: .constant(.mixed), in: .mixed)
}
```

}

// MARK: - Data Models

struct StageElement: Identifiable, Codable {
var id = UUID()
var name: String
var type: ElementType
var position: SIMD3<Float>
var rotation: Float       // Y-axis rotation in degrees
var scale: Float
var color: ElementColor
var isActive: Bool
var notes: String

```
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
```

}

struct EventInfo: Codable {
var name: String = “Nouvel Événement”
var date: Date = Date()
var venue: String = “”
var capacity: Int = 0
var notes: String = “”
}

// MARK: - View Model

class StageViewModel: ObservableObject {
@Published var elements: [StageElement] = []
@Published var selectedElement: StageElement?
@Published var isImmersiveSpaceOpen = false
@Published var eventInfo = EventInfo()
@Published var showAddSheet = false
@Published var showEventSheet = false

```
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
}
```

}

// MARK: - Main Content View (Control Panel)

struct ContentView: View {
@EnvironmentObject var model: StageViewModel
@Environment(.openImmersiveSpace) var openImmersiveSpace
@Environment(.dismissImmersiveSpace) var dismissImmersiveSpace

```
var body: some View {
    NavigationSplitView {
        SidebarView()
    } detail: {
        DetailView()
    }
    .toolbar {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                model.showEventSheet = true
            } label: {
                Label("Événement", systemImage: "calendar.badge.plus")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                model.showAddSheet = true
            } label: {
                Label("Ajouter", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task {
                    if model.isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        model.isImmersiveSpaceOpen = false
                    } else {
                        await openImmersiveSpace(id: "StageSpace")
                        model.isImmersiveSpaceOpen = true
                    }
                }
            } label: {
                Label(
                    model.isImmersiveSpaceOpen ? "Fermer 3D" : "Vue 3D",
                    systemImage: model.isImmersiveSpaceOpen ? "xmark.circle" : "vision.pro"
                )
            }
            .buttonStyle(.bordered)
            .tint(model.isImmersiveSpaceOpen ? .red : .green)
        }
    }
    .navigationTitle(model.eventInfo.name)
    .sheet(isPresented: $model.showAddSheet) {
        AddElementSheet()
    }
    .sheet(isPresented: $model.showEventSheet) {
        EventInfoSheet()
    }
}
```

}

// MARK: - Sidebar

struct SidebarView: View {
@EnvironmentObject var model: StageViewModel

```
var body: some View {
    List(selection: Binding(
        get: { model.selectedElement?.id },
        set: { id in model.selectedElement = model.elements.first(where: { $0.id == id }) }
    )) {
        ForEach(StageElement.ElementType.allCases, id: \.self) { type in
            let filtered = model.elements.filter { $0.type == type }
            if !filtered.isEmpty {
                Section(type.rawValue) {
                    ForEach(filtered) { element in
                        ElementRow(element: element)
                            .tag(element.id)
                    }
                }
            }
        }
    }
    .navigationTitle("Éléments (\(model.elements.count))")
    .listStyle(.sidebar)
}
```

}

struct ElementRow: View {
@EnvironmentObject var model: StageViewModel
let element: StageElement

```
var body: some View {
    HStack {
        Image(systemName: element.type.icon)
            .foregroundStyle(element.isActive ? element.color.swiftUIColor : .gray)
            .frame(width: 24)
        VStack(alignment: .leading, spacing: 2) {
            Text(element.name)
                .font(.body)
                .foregroundStyle(element.isActive ? .primary : .secondary)
            Text(element.type.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        Spacer()
        Circle()
            .fill(element.isActive ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
    }
    .padding(.vertical, 2)
    .contextMenu {
        Button {
            model.toggleActive(element)
        } label: {
            Label(element.isActive ? "Désactiver" : "Activer",
                  systemImage: element.isActive ? "pause.circle" : "play.circle")
        }
        Divider()
        Button(role: .destructive) {
            model.removeElement(element)
        } label: {
            Label("Supprimer", systemImage: "trash")
        }
    }
}
```

}

// MARK: - Detail View

struct DetailView: View {
@EnvironmentObject var model: StageViewModel

```
var body: some View {
    if let element = model.selectedElement,
       let binding = Binding(unwrapping: $model.selectedElement) {
        ElementDetailView(element: binding)
    } else {
        StageOverviewView()
    }
}
```

}

struct StageOverviewView: View {
@EnvironmentObject var model: StageViewModel

```
var activeCount: Int { model.elements.filter { $0.isActive }.count }

var body: some View {
    ScrollView {
        VStack(spacing: 20) {
            // Event header
            VStack(spacing: 8) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                Text(model.eventInfo.name)
                    .font(.largeTitle.bold())
                if !model.eventInfo.venue.isEmpty {
                    Text(model.eventInfo.venue)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Text(model.eventInfo.date.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 20)

            // Stats
            HStack(spacing: 16) {
                StatCard(title: "Éléments", value: "\(model.elements.count)", icon: "square.3.layers.3d", color: .blue)
                StatCard(title: "Actifs", value: "\(activeCount)", icon: "checkmark.circle.fill", color: .green)
                StatCard(title: "Inactifs", value: "\(model.elements.count - activeCount)", icon: "pause.circle.fill", color: .orange)
                if model.eventInfo.capacity > 0 {
                    StatCard(title: "Capacité", value: "\(model.eventInfo.capacity)", icon: "person.3.fill", color: .purple)
                }
            }

            // Type breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Répartition par type")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(StageElement.ElementType.allCases, id: \.self) { type in
                    let count = model.elements.filter { $0.type == type }.count
                    if count > 0 {
                        HStack {
                            Image(systemName: type.icon)
                                .frame(width: 24)
                                .foregroundStyle(.secondary)
                            Text(type.rawValue)
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                                .bold()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    }
                }
            }

            if !model.eventInfo.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    Text(model.eventInfo.notes)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 30)
    }
    .navigationTitle("Vue d'ensemble")
}
```

}

struct StatCard: View {
let title: String
let value: String
let icon: String
let color: Color

```
var body: some View {
    VStack(spacing: 6) {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
        Text(value)
            .font(.title.bold())
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
}
```

}

// MARK: - Element Detail View

struct ElementDetailView: View {
@EnvironmentObject var model: StageViewModel
@Binding var element: StageElement

```
var body: some View {
    Form {
        Section("Informations") {
            TextField("Nom", text: $element.name)
            Picker("Type", selection: $element.type) {
                ForEach(StageElement.ElementType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            Picker("Couleur", selection: $element.color) {
                ForEach(StageElement.ElementColor.allCases, id: \.self) { color in
                    HStack {
                        Circle().fill(color.swiftUIColor).frame(width: 12, height: 12)
                        Text(color.rawValue)
                    }.tag(color)
                }
            }
            Toggle("Actif", isOn: $element.isActive)
        }

        Section("Position 3D") {
            LabeledContent("X (gauche/droite)") {
                Slider(value: $element.position.x, in: -5...5, step: 0.1)
                Text(String(format: "%.1f m", element.position.x))
                    .frame(width: 50)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Y (hauteur)") {
                Slider(value: $element.position.y, in: 0...5, step: 0.1)
                Text(String(format: "%.1f m", element.position.y))
                    .frame(width: 50)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Z (profondeur)") {
                Slider(value: $element.position.z, in: -6...0, step: 0.1)
                Text(String(format: "%.1f m", element.position.z))
                    .frame(width: 50)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Rotation") {
                Slider(value: $element.rotation, in: -180...180, step: 5)
                Text(String(format: "%.0f°", element.rotation))
                    .frame(width: 50)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Échelle") {
                Slider(value: $element.scale, in: 0.1...3.0, step: 0.1)
                Text(String(format: "%.1fx", element.scale))
                    .frame(width: 50)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Notes") {
            TextEditor(text: $element.notes)
                .frame(minHeight: 80)
        }

        Section {
            Button(role: .destructive) {
                model.removeElement(element)
            } label: {
                Label("Supprimer cet élément", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }
    .navigationTitle(element.name)
    .onChange(of: element) { _, newValue in
        model.updateElement(newValue)
    }
}
```

}

// MARK: - Add Element Sheet

struct AddElementSheet: View {
@EnvironmentObject var model: StageViewModel
@Environment(.dismiss) var dismiss

```
@State private var name = ""
@State private var type: StageElement.ElementType = .lighting
@State private var color: StageElement.ElementColor = .white
@State private var notes = ""

var body: some View {
    NavigationStack {
        Form {
            Section("Nouvel élément") {
                TextField("Nom de l'élément", text: $name)
                Picker("Type", selection: $type) {
                    ForEach(StageElement.ElementType.allCases, id: \.self) { t in
                        Label(t.rawValue, systemImage: t.icon).tag(t)
                    }
                }
                Picker("Couleur", selection: $color) {
                    ForEach(StageElement.ElementColor.allCases, id: \.self) { c in
                        HStack {
                            Circle().fill(c.swiftUIColor).frame(width: 12, height: 12)
                            Text(c.rawValue)
                        }.tag(c)
                    }
                }
            }
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        }
        .navigationTitle("Ajouter un élément")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Ajouter") {
                    let element = StageElement(
                        name: name.isEmpty ? type.rawValue : name,
                        type: type,
                        position: SIMD3<Float>(0, 0, -3),
                        rotation: 0,
                        scale: 1.0,
                        color: color,
                        isActive: true,
                        notes: notes
                    )
                    model.addElement(element)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    .frame(minWidth: 400, minHeight: 400)
}
```

}

// MARK: - Event Info Sheet

struct EventInfoSheet: View {
@EnvironmentObject var model: StageViewModel
@Environment(.dismiss) var dismiss

```
var body: some View {
    NavigationStack {
        Form {
            Section("Événement") {
                TextField("Nom de l'événement", text: $model.eventInfo.name)
                TextField("Lieu / Venue", text: $model.eventInfo.venue)
                DatePicker("Date", selection: $model.eventInfo.date)
                Stepper("Capacité : \(model.eventInfo.capacity)", value: $model.eventInfo.capacity, in: 0...100000, step: 100)
            }
            Section("Notes") {
                TextEditor(text: $model.eventInfo.notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("Infos événement")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") { dismiss() }
            }
        }
    }
    .frame(minWidth: 400, minHeight: 450)
}
```

}

// MARK: - 3D Immersive View

import RealityKit
import RealityKitContent

struct StageImmersiveView: View {
@EnvironmentObject var model: StageViewModel

```
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
```

}

// MARK: - Utility

extension Binding {
init?(unwrapping base: Binding<Value?>) {
guard let value = base.wrappedValue else { return nil }
self.init(
get: { base.wrappedValue ?? value },
set: { base.wrappedValue = $0 }
)
}
}
