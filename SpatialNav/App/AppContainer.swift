//
//  AppContainer.swift
//  SpatialNav
//

import Foundation
import os

/// Composition root — the only place in the app where concrete service types
/// are constructed. Everything downstream receives protocols via initializer
/// injection, so any piece can be tested against mocks.
@MainActor
final class AppContainer {
    let meshStore: MeshStore
    let arSessionManager: ARSessionManager
    let cameraAuthorizer: any CameraAuthorizing
    let spaceStore: SpaceStore
    let objectDetection: ObjectDetectionUseCase?

    init() {
        let meshStore = MeshStore()
        self.meshStore = meshStore
        self.arSessionManager = ARSessionManager(meshStore: meshStore)
        self.cameraAuthorizer = CameraPermissionService()
        let spacesDirectory = (try? SpaceStore.defaultDirectory())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("Spaces", isDirectory: true)
        self.spaceStore = SpaceStore(directory: spacesDirectory)

        do {
            let detector = try YOLODetectionService()
            self.objectDetection = ObjectDetectionUseCase(provider: arSessionManager, detector: detector)
        } catch {
            self.objectDetection = nil
            Logger(subsystem: "com.thetpine.spatialnav", category: "ml")
                .notice("Object detection disabled — no CoreML model bundled. See scripts/convert_yolo_to_coreml.py")
        }
    }

    func makeNavigationScreen() -> NavigationScreen {
        let sonar = SonarSweepUseCase(
            provider: arSessionManager,
            hazardAnalyzer: FloorDiscontinuityDetector()
        )
        return NavigationScreen(
            viewModel: NavigationViewModel(
                provider: arSessionManager,
                meshStore: meshStore,
                cameraAuthorizer: cameraAuthorizer,
                sonar: sonar,
                objectDetection: objectDetection
            ),
            arViewContainer: ARViewContainer(session: arSessionManager.session),
            makeSpacesViewModel: { [arSessionManager, spaceStore] in
                SpacesViewModel(store: spaceStore, provider: arSessionManager)
            }
        )
    }
}
