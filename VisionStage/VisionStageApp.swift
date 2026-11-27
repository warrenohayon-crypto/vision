//
//  VisionStageApp.swift
//  VisionStage
//
//  Created by Warren Ohayon on 05/03/2026.
//

import SwiftUI

// MARK: - App Entry Point

@main
struct VisionStageApp: App {
    @StateObject private var stageModel = StageViewModel()

    var body: some Scene {
        // Main 2D window (control panel)
        WindowGroup("Stage Vision", id: "main") {
            ContentView()
                .environmentObject(stageModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 900, height: 600)

        // 3D immersive space for the stage
        ImmersiveSpace(id: StageViewModel.immersiveSpaceID) {
            StageImmersiveView()
                .environmentObject(stageModel)
                // Keep the toolbar button in sync even when the space is
                // closed by the system (e.g. Digital Crown) rather than the button.
                .onAppear { stageModel.isImmersiveSpaceOpen = true }
                .onDisappear { stageModel.isImmersiveSpaceOpen = false }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
