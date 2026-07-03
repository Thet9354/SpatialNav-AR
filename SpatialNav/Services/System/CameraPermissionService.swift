//
//  CameraPermissionService.swift
//  SpatialNav
//

import AVFoundation

nonisolated struct CameraPermissionService: CameraAuthorizing {
    var status: CameraAuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .authorized
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .denied
        }
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
