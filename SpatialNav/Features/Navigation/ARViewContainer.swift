//
//  ARViewContainer.swift
//  SpatialNav
//

import ARKit
import RealityKit
import SwiftUI

/// Render-layer boundary: the one place outside Services/AR that touches an
/// ARKit type, because ARView must be attached to the real session.
struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    var showsMeshOverlay: Bool = false

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.session = session
        arView.renderOptions.insert([
            .disableMotionBlur,
            .disableDepthOfField,
            .disablePersonOcclusion,
            .disableGroundingShadows,
        ])
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // User-controlled (Settings → "Show scan overlay") so a sighted
        // companion can see what the app senses; formerly DEBUG-only.
        if showsMeshOverlay {
            uiView.debugOptions.insert(.showSceneUnderstanding)
        } else {
            uiView.debugOptions.remove(.showSceneUnderstanding)
        }
    }

    func showingMeshOverlay(_ show: Bool) -> Self {
        var copy = self
        copy.showsMeshOverlay = show
        return copy
    }
}
