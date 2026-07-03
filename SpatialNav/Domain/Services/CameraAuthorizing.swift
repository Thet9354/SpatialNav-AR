//
//  CameraAuthorizing.swift
//  SpatialNav
//

import Foundation

nonisolated enum CameraAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

nonisolated protocol CameraAuthorizing: Sendable {
    var status: CameraAuthorizationStatus { get }
    func requestAccess() async -> Bool
}
