//
//  ClockDirection.swift
//  SpatialNav
//

import Foundation

/// Clock-face direction as used in orientation & mobility (O&M) instruction:
/// 12 o'clock is straight ahead, 3 o'clock is the user's right, 9 o'clock the left.
nonisolated enum ClockDirection: Int, CaseIterable, Sendable, Equatable, Codable {
    case one = 1, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve

    /// Bearing is in radians relative to the camera's forward axis,
    /// positive clockwise (toward the user's right) when viewed from above.
    init(bearing: Float) {
        let hourAngle = Float.pi / 6
        var hour = Int((bearing / hourAngle).rounded()) % 12
        if hour < 0 { hour += 12 }
        self.init(rawValue: hour == 0 ? 12 : hour)!
    }

    var spokenDescription: String {
        "\(rawValue) o'clock"
    }
}
