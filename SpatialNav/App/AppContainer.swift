//
//  AppContainer.swift
//  SpatialNav
//

import Foundation
import os

/// Composition root — the only place in the app where concrete service types
/// are constructed. Everything downstream receives protocols via initializer
/// injection, so any piece can be tested against mocks.
@MainActor
@Observable
final class AppContainer {
    let meshStore: MeshStore
    let arSessionManager: ARSessionManager
    let cameraAuthorizer: any CameraAuthorizing
    let spaceStore: SpaceStore
    let objectDetection: ObjectDetectionUseCase?
    let governor: PerformanceGovernor
    let itemStore: ItemStore
    let findItem: FindItemUseCase
    let audioEngine: SpatialAudioEngine
    let speechQueue: SpeechQueue
    let hapticService: HapticEngineService
    let settingsStore: SettingsStore
    private(set) var needsOnboarding: Bool

    init() {
        let meshStore = MeshStore()
        self.meshStore = meshStore
        self.arSessionManager = ARSessionManager(meshStore: meshStore)
        self.cameraAuthorizer = CameraPermissionService()
        let spacesDirectory = (try? SpaceStore.defaultDirectory())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("Spaces", isDirectory: true)
        self.spaceStore = SpaceStore(directory: spacesDirectory)

        do {
            let detector = try YOLODetectionService()
            self.objectDetection = ObjectDetectionUseCase(provider: arSessionManager, detector: detector)
        } catch {
            self.objectDetection = nil
            Logger(subsystem: "com.thetpine.spatialnav", category: "ml")
                .notice("Object detection disabled — no CoreML model bundled. See scripts/convert_yolo_to_coreml.py")
        }

        self.governor = PerformanceGovernor()
        let itemsDirectory = (try? ItemStore.defaultDirectory())
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("Items", isDirectory: true)
        let itemStore = ItemStore(directory: itemsDirectory)
        self.itemStore = itemStore
        self.findItem = FindItemUseCase(
            provider: arSessionManager,
            featurePrinter: FeaturePrintService(),
            itemStore: itemStore
        )
        self.audioEngine = SpatialAudioEngine()
        self.speechQueue = SpeechQueue()
        self.hapticService = HapticEngineService()
        let settingsStore = SettingsStore()
        self.settingsStore = settingsStore
        self.needsOnboarding = !settingsStore.hasSavedProfile
    }

    func completeOnboarding(with profile: FeedbackProfile) {
        settingsStore.save(profile)
        needsOnboarding = false
    }

    func makeNavigationScreen() -> NavigationScreen {
        let sonar = SonarSweepUseCase(
            provider: arSessionManager,
            hazardAnalyzer: FloorDiscontinuityDetector()
        )
        return NavigationScreen(
            viewModel: NavigationViewModel(
                provider: arSessionManager,
                meshStore: meshStore,
                cameraAuthorizer: cameraAuthorizer,
                sonar: sonar,
                objectDetection: objectDetection,
                governor: governor,
                audio: audioEngine,
                speech: speechQueue,
                haptics: hapticService,
                settings: settingsStore
            ),
            arViewContainer: ARViewContainer(session: arSessionManager.session),
            makeSpacesViewModel: { [arSessionManager, spaceStore] in
                SpacesViewModel(store: spaceStore, provider: arSessionManager)
            },
            makeItemsViewModel: { [findItem] in
                ItemsViewModel(findItem: findItem)
            },
            makeSettingsViewModel: { [settingsStore] onChange in
                SettingsViewModel(store: settingsStore, onChange: onChange)
            }
        )
    }
}
