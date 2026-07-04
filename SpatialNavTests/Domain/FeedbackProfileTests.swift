//
//  FeedbackProfileTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct FeedbackProfileTests {

    @Test func roundTripsThroughJSON() throws {
        var profile = FeedbackProfile.default
        profile.mode = .deafBlind
        profile.showScanOverlay = true
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(FeedbackProfile.self, from: data)
        #expect(decoded == profile)
    }

    @Test func profilesSavedByOlderBuildsStillDecode() throws {
        // JSON without the showScanOverlay key, as an older build wrote it:
        // decoding must succeed with the default instead of resetting settings.
        let legacyJSON = """
        {"mode":"hybrid","verbosity":"normal","speechRate":0.5,
         "minimumAlertDistance":3,"distanceUnit":"meters","strideLengthMeters":0.7}
        """
        let decoded = try JSONDecoder().decode(FeedbackProfile.self, from: Data(legacyJSON.utf8))
        #expect(decoded.mode == .hybrid)
        #expect(decoded.showScanOverlay == false)
    }
}
