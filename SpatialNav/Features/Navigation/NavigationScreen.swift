//
//  NavigationScreen.swift
//  SpatialNav
//
//  Named NavigationScreen (not NavigationView) to avoid shadowing SwiftUI.NavigationView.
//

import SwiftUI
import UIKit

struct NavigationScreen: View {
    @State private var viewModel: NavigationViewModel
    @State private var showingSpaces = false
    @State private var showingItems = false
    @State private var showingSettings = false
    private let arViewContainer: ARViewContainer
    private let makeSpacesViewModel: () -> SpacesViewModel
    private let makeItemsViewModel: () -> ItemsViewModel
    private let makeSettingsViewModel: (@escaping (FeedbackProfile) -> Void) -> SettingsViewModel
    @Environment(\.openURL) private var openURL

    init(
        viewModel: NavigationViewModel,
        arViewContainer: ARViewContainer,
        makeSpacesViewModel: @escaping () -> SpacesViewModel,
        makeItemsViewModel: @escaping () -> ItemsViewModel,
        makeSettingsViewModel: @escaping (@escaping (FeedbackProfile) -> Void) -> SettingsViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.arViewContainer = arViewContainer
        self.makeSpacesViewModel = makeSpacesViewModel
        self.makeItemsViewModel = makeItemsViewModel
        self.makeSettingsViewModel = makeSettingsViewModel
    }

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .running, .interrupted:
                arViewContainer
                    .ignoresSafeArea()
                    .accessibilityLabel("Camera view of your surroundings")
                statusOverlay
            case .idle:
                ProgressView("Starting spatial session…")
            case .unsupportedDevice:
                messageView(
                    systemImage: "exclamationmark.triangle",
                    title: "Device Not Supported",
                    message: "SpatialNav needs a device that supports augmented reality world tracking."
                )
            case .permissionDenied:
                permissionDeniedView
            case .failed(let message):
                messageView(
                    systemImage: "exclamationmark.triangle",
                    title: "Session Failed",
                    message: message
                ) {
                    Button("Try Again") {
                        Task { await viewModel.start() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showingSpaces) {
            SpacesSheet(viewModel: makeSpacesViewModel())
        }
        .sheet(isPresented: $showingItems) {
            ItemsSheet(viewModel: makeItemsViewModel()) { item in
                viewModel.guide(to: item)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(viewModel: makeSettingsViewModel { profile in
                viewModel.apply(profile: profile)
            })
        }
    }

    private var statusOverlay: some View {
        VStack {
            if viewModel.phase == .interrupted {
                Text("Session paused")
                    .font(.headline)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Guidance paused")
            }
            if let hazard = viewModel.activeHazards.max(by: { $0.priority < $1.priority }) {
                Text(hazard.kind.warningDescription)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.red, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityAddTraits(.isStaticText)
            }
            HStack {
                Spacer()
                Button {
                    showingItems = true
                } label: {
                    Label("Items", systemImage: "viewfinder")
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityHint("Save an item you're pointing at, or find a saved one")
                .accessibilityIdentifier(AccessibilityIdentifiers.itemsButton)
                Button {
                    showingSpaces = true
                } label: {
                    Label("Spaces", systemImage: "square.grid.2x2")
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityHint("Save this room or return to a saved one")
                .accessibilityIdentifier(AccessibilityIdentifiers.spacesButton)
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Feedback style, speech rate, and alert distance")
                .accessibilityIdentifier(AccessibilityIdentifiers.settingsButton)
            }
            .padding(.horizontal)
            Spacer()
            if let item = viewModel.guidedItem, let guidance = viewModel.itemGuidance {
                HStack {
                    Text(guidanceDescription(item: item, guidance: guidance))
                        .font(.headline)
                    Spacer()
                    Button("Stop") { viewModel.stopGuiding() }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Stop guiding to \(item.name)")
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.trackingQuality.statusDescription)
                    .font(.headline)
                Text(nearestObstacleDescription)
                    .font(.subheadline)
                if viewModel.objectDetectionAvailable {
                    Text(detectedObjectsDescription)
                        .font(.subheadline)
                }
                if viewModel.lidarAvailable {
                    Text("\(viewModel.worldMappingStatus.statusDescription) · \(viewModel.meshAnchorCount) mesh regions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("LiDAR unavailable — reduced obstacle detection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if viewModel.processingTier < .full {
                    Text("Power saving — reduced detail")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(AccessibilityIdentifiers.statusPanel)
        }
    }

    private var nearestObstacleDescription: String {
        guard let obstacle = viewModel.nearestObstacle else { return "Path clear" }
        let distance = String(format: "%.1f", obstacle.distance)
        return "Nearest obstacle: \(distance) m at \(obstacle.direction.spokenDescription)"
    }

    private func guidanceDescription(item: SavedItem, guidance: ItemGuidance) -> String {
        let distance = SpokenDistance.description(
            meters: guidance.distance,
            unit: viewModel.profile.distanceUnit,
            strideLengthMeters: viewModel.profile.strideLengthMeters
        )
        var description = "\(item.name) · \(distance) at \(guidance.direction.spokenDescription)"
        if guidance.heightDelta > 0.3 {
            description += ", above you"
        } else if guidance.heightDelta < -1.2 {
            description += ", low down"
        }
        return description
    }

    private var detectedObjectsDescription: String {
        guard let object = viewModel.detectedObjects.first else { return "No objects recognized" }
        var description = object.label
        if let distance = object.distance {
            description += String(format: " · %.1f m", distance)
        }
        if let direction = object.direction {
            description += " at \(direction.spokenDescription)"
        }
        if viewModel.detectedObjects.count > 1 {
            description += " (+\(viewModel.detectedObjects.count - 1) more)"
        }
        return description
    }

    private var permissionDeniedView: some View {
        messageView(
            systemImage: "camera",
            title: "Camera Access Needed",
            message: "SpatialNav guides you by sensing the space around you with the camera. Images are processed on this device only and never stored or shared."
        ) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func messageView(
        systemImage: String,
        title: String,
        message: String,
        @ViewBuilder actions: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
            actions()
        }
        .padding(32)
        .accessibilityElement(children: .combine)
    }
}
