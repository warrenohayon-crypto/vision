//
//  ContentView.swift
//  VisionStage
//
//  Created by Warren Ohayon on 05/03/2026.
//

import SwiftUI

// MARK: - Main Content View (Control Panel)

struct ContentView: View {
    @EnvironmentObject var model: StageViewModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
                // The toolbar must live on a column: attached to the split
                // view itself, visionOS doesn't show it at all.
                .toolbar { toolbarContent }
        }
        .sheet(isPresented: $model.showAddSheet) {
            AddElementSheet()
        }
        .sheet(isPresented: $model.showEventSheet) {
            EventInfoSheet()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                        let result = await openImmersiveSpace(id: StageViewModel.immersiveSpaceID)
                        model.isImmersiveSpaceOpen = (result == .opened)
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
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var model: StageViewModel

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
}

struct ElementRow: View {
    @EnvironmentObject var model: StageViewModel
    let element: StageElement

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
}

// MARK: - Detail View

struct DetailView: View {
    @EnvironmentObject var model: StageViewModel

    var body: some View {
        if let binding = Binding(unwrapping: $model.selectedElement) {
            ElementDetailView(element: binding)
        } else {
            StageOverviewView()
        }
    }
}

struct StageOverviewView: View {
    @EnvironmentObject var model: StageViewModel

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
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

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
}

// MARK: - Element Detail View

struct ElementDetailView: View {
    @EnvironmentObject var model: StageViewModel
    @Binding var element: StageElement

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
}

// MARK: - Add Element Sheet

struct AddElementSheet: View {
    @EnvironmentObject var model: StageViewModel
    @Environment(\.dismiss) var dismiss

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
}

// MARK: - Event Info Sheet

struct EventInfoSheet: View {
    @EnvironmentObject var model: StageViewModel
    @Environment(\.dismiss) var dismiss

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
}

// MARK: - Utility

extension Binding {
    /// Turns a `Binding<Value?>` into a `Binding<Value>` while the value is non-nil.
    init?(unwrapping base: Binding<Value?>) {
        guard let value = base.wrappedValue else { return nil }
        self.init(
            get: { base.wrappedValue ?? value },
            set: { base.wrappedValue = $0 }
        )
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(StageViewModel())
}
