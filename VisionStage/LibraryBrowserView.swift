//
//  LibraryBrowserView.swift
//  VisionStage
//
//  Browse / search the production library and add products to the stage.
//

import SwiftUI

struct LibraryBrowserView: View {
    @EnvironmentObject var model: StageViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var category: LibraryCategory? = nil
    @State private var brand: String? = nil
    @State private var search = ""
    @State private var showCustom = false
    @State private var lastAdded: String?

    private var results: [LibraryProduct] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return ProductLibrary.all.filter { p in
            (category == nil || p.category == category) &&
            (brand == nil || p.brand == brand) &&
            (q.isEmpty || "\(p.brand) \(p.model) \(p.family) \(p.specs)".lowercased().contains(q))
        }
    }

    /// Results grouped by family, keeping catalog order.
    private var groups: [(family: String, items: [LibraryProduct])] {
        var order: [String] = []
        var dict: [String: [LibraryProduct]] = [:]
        for p in results {
            let key = category == nil ? "\(p.category.rawValue) · \(p.family)" : p.family
            if dict[key] == nil { order.append(key) }
            dict[key, default: []].append(p)
        }
        return order.map { ($0, dict[$0]!) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryBar
                    .padding(.vertical, 10)
                List {
                    ForEach(groups, id: \.family) { group in
                        Section("\(group.family) (\(group.items.count))") {
                            ForEach(group.items) { product in
                                NavigationLink(value: product) {
                                    ProductRow(product: product) { add(product) }
                                }
                            }
                        }
                    }
                }
                .overlay {
                    if results.isEmpty {
                        ContentUnavailableView.search(text: search)
                    }
                }
            }
            .navigationTitle("Bibliothèque (\(results.count) / \(ProductLibrary.all.count))")
            .searchable(text: $search, prompt: "Marque, modèle, type… (ex. Robe, K2, wash)")
            .navigationDestination(for: LibraryProduct.self) { product in
                ProductDetailView(product: product) { qty in add(product, quantity: qty) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    brandMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustom = true
                    } label: {
                        Label("Élément personnalisé", systemImage: "square.and.pencil")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let lastAdded {
                    Label("\(lastAdded) ajouté à la scène", systemImage: "checkmark.circle.fill")
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .glassBackgroundEffect()
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showCustom) {
                AddElementSheet()
            }
        }
        .frame(minWidth: 900, minHeight: 650)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Tout", icon: "square.grid.2x2", count: ProductLibrary.all.count, selected: category == nil) {
                    category = nil; brand = nil
                }
                ForEach(LibraryCategory.allCases) { c in
                    chip(c.rawValue, icon: c.icon, count: ProductLibrary.count(in: c), selected: category == c) {
                        category = c; brand = nil
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ title: String, icon: String, count: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("\(title) \(count)", systemImage: icon)
                .font(.callout)
                .padding(.horizontal, 6)
        }
        .buttonStyle(.bordered)
        .tint(selected ? .accentColor : nil)
        .buttonBorderShape(.capsule)
        .overlay {
            if selected { Capsule().stroke(Color.accentColor, lineWidth: 2) }
        }
    }

    private var brandMenu: some View {
        Menu {
            Button("Toutes les marques") { brand = nil }
            Divider()
            ForEach(ProductLibrary.brands(in: category), id: \.self) { b in
                Button {
                    brand = b
                } label: {
                    if brand == b { Label(b, systemImage: "checkmark") } else { Text(b) }
                }
            }
        } label: {
            Label(brand ?? "Marques", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func add(_ product: LibraryProduct, quantity: Int? = nil) {
        model.addProduct(product, quantity: quantity)
        withAnimation { lastAdded = product.displayName }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { if lastAdded == product.displayName { lastAdded = nil } }
        }
    }
}

// MARK: - Row

struct ProductRow: View {
    let product: LibraryProduct
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: product.category.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(product.brand).font(.caption).foregroundStyle(.secondary)
                }
                Text(product.model).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
            .buttonStyle(.borderless)
            .help("Ajouter à la scène")
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        var parts = [product.dimensionText]
        if product.weight > 0 { parts.append(String(format: "%.0f kg", product.weight)) }
        if product.power > 0 { parts.append("\(product.power) W") }
        if !product.specs.isEmpty { parts.append(product.specs) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Product detail

struct ProductDetailView: View {
    let product: LibraryProduct
    let onAdd: (Int?) -> Void
    @State private var quantity = 1

    private var isStackable: Bool { product.shape == .lineArrayBox || product.shape == .subwoofer }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: product.category.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text(product.brand).foregroundStyle(.secondary)
                        Text(product.model).font(.largeTitle.bold())
                        Text("\(product.category.rawValue) · \(product.family)")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            Section("Caractéristiques (approx.)") {
                LabeledContent("Dimensions (L × H × P)", value: product.dimensionText)
                if product.weight > 0 {
                    LabeledContent("Poids", value: String(format: "%.1f kg", product.weight))
                }
                if product.power > 0 {
                    LabeledContent("Consommation", value: "\(product.power) W")
                }
                if !product.specs.isEmpty {
                    LabeledContent("Infos", value: product.specs)
                }
            }
            if isStackable {
                Section("Configuration") {
                    Stepper(product.shape == .lineArrayBox ? "Boîtes dans le cluster : \(quantity)" : "Nombre de subs : \(quantity)",
                            value: $quantity, in: 1...24)
                }
            }
            Section {
                Button {
                    onAdd(isStackable ? quantity : nil)
                } label: {
                    Label("Ajouter à la scène", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } footer: {
                Text("Valeurs indicatives pour l'implantation. Vérifiez toujours la fiche technique du fabricant avant toute charge ou accroche.")
            }
        }
        .navigationTitle(product.displayName)
        .onAppear {
            if product.shape == .lineArrayBox { quantity = 8 }
            if product.shape == .subwoofer { quantity = 4 }
        }
    }
}
