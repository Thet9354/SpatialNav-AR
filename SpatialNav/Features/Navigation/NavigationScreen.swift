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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

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
                    .showingMeshOverlay(viewModel.profile.showScanOverlay)
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
        // VoiceOver's system-wide two-finger double-tap: the pause idiom
        // blind users already know from every media app.
        .accessibilityAction(.magicTap) { viewModel.togglePause() }
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
                    .background(panelBackground, in: RoundedRectangle(cornerRadius: 12))
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
            if viewModel.isPaused {
                Text("Guidance paused")
                    .font(.headline)
                    .padding(12)
                    .background(panelBackground, in: RoundedRectangle(cornerRadius: 12))
            }
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
                .background(panelBackground, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
            }
            controlBar
                .padding(.horizontal)
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
            .background(panelBackground, in: RoundedRectangle(cornerRadius: 16))
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

    /// Translucent materials wash out over a bright camera feed; when the user
    /// asks for Reduce Transparency, honor it with a solid backdrop.
    private var panelBackground: AnyShapeStyle {
        reduceTransparency
            ? AnyShapeStyle(Color(uiColor: .systemBackground))
            : AnyShapeStyle(.thinMaterial)
    }

    /// Large thumb-reachable targets in a fixed place VoiceOver users can find
    /// predictably — the old top-corner buttons were developer-sized.
    private var controlBar: some View {
        HStack(spacing: 8) {
            controlButton(
                title: viewModel.isPaused ? "Resume" : "Pause",
                systemImage: viewModel.isPaused ? "play.fill" : "pause.fill",
                hint: "Pauses or resumes all guidance. Also two-finger double-tap with VoiceOver."
            ) { viewModel.togglePause() }
            controlButton(
                title: "Describe",
                systemImage: "text.bubble",
                hint: "Speaks what is around you right now"
            ) { viewModel.describeScene() }
            controlButton(
                title: "Items",
                systemImage: "viewfinder",
                hint: "Save an item you're pointing at, or find a saved one",
                identifier: AccessibilityIdentifiers.itemsButton
            ) { showingItems = true }
            controlButton(
                title: "Spaces",
                systemImage: "square.grid.2x2",
                hint: "Save this room or return to a saved one",
                identifier: AccessibilityIdentifiers.spacesButton
            ) { showingSpaces = true }
            controlButton(
                title: "Settings",
                systemImage: "gearshape",
                hint: "Feedback style, speech rate, and alert distance",
                identifier: AccessibilityIdentifiers.settingsButton
            ) { showingSettings = true }
        }
    }

    private func controlButton(
        title: String,
        systemImage: String,
        hint: String,
        identifier: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(panelBackground, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(title)
        .accessibilityHint(hint)
        .accessibilityIdentifier(identifier ?? "navigation.\(title.lowercased())Button")
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
