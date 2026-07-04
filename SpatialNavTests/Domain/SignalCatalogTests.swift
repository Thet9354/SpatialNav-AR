//
//  SignalCatalogTests.swift
//  SpatialNavTests
//

import Foundation
import Testing
@testable import SpatialNav

struct SignalCatalogTests {

    @Test func catalogIsNonEmptyWithUniqueIds() {
        let ids = SignalCatalog.all.map(\.id)
        #expect(!ids.isEmpty)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyEntryHasTeachableCopy() {
        for demo in SignalCatalog.all {
            #expect(!demo.title.isEmpty)
            #expect(!demo.explanation.isEmpty)
        }
    }

    @Test func catalogCoversTheCoreVocabulary() {
        let kinds = SignalCatalog.all.map(\.event.kind)
        #expect(kinds.contains(.hazardWarning(.dropOff)))
        #expect(kinds.contains(.obstacleProximity))
        #expect(kinds.contains(.itemPing))
    }

    @Test func proximityDemosBracketTheDistanceRange() {
        // Near and far obstacle demos must actually sound/feel different.
        let distances = SignalCatalog.all
            .filter { $0.event.kind == .obstacleProximity }
            .compactMap(\.event.distance)
        #expect(distances.count == 2)
        #expect(distances.min()! < 1.0)
        #expect(distances.max()! > 3.0)
    }
}
