//
//  AppContainer.swift
//  SpatialNav
//

import Foundation

/// Composition root — the only place in the app where concrete service types
/// are constructed. Everything downstream receives protocols via initializer
/// injection, so any piece can be tested against mocks.
@MainActor
final class AppContainer {
    let meshStore: MeshStore
    let arSessionManager: ARSessionManager
    let cameraAuthorizer: any CameraAuthorizing

    init() {
        let meshStore = MeshStore()
        self.meshStore = meshStore
        self.arSessionManager = ARSessionManager(meshStore: meshStore)
        self.cameraAuthorizer = CameraPermissionService()
    }

    func makeNavigationScreen() -> NavigationScreen {
        NavigationScreen(
            viewModel: NavigationViewModel(
                provider: arSessionManager,
                meshStore: meshStore,
                cameraAuthorizer: cameraAuthorizer
            ),
            arViewContainer: ARViewContainer(session: arSessionManager.session)
        )
    }
}
