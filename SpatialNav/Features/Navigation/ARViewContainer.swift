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

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.session = session
        arView.renderOptions.insert([
            .disableMotionBlur,
            .disableDepthOfField,
            .disablePersonOcclusion,
            .disableGroundingShadows,
        ])
        #if DEBUG
        arView.debugOptions.insert(.showSceneUnderstanding)
        #endif
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
