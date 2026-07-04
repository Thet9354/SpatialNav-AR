//
//  SpatialNavApp.swift
//  SpatialNav
//
//  Created by Phoon Thet Pine on 3/7/26.
//

import SwiftUI

@main
struct SpatialNavApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            if container.needsOnboarding {
                OnboardingView { profile in
                    container.completeOnboarding(with: profile)
                }
            } else {
                container.makeNavigationScreen()
            }
        }
    }
}
