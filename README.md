# SpatialNav AR

**An indoor spatial-awareness assistant for blind and low-vision users.**
iPhone LiDAR + on-device ML + spatial audio + a haptic vocabulary — no server, no account, no data collected.

Point the phone forward and walk: obstacles ping from their true 3D direction like sonar, drop-offs and stairs trigger unmistakable warnings, everyday objects are recognized and located ("keyboard, 1 meter at 12 o'clock"), misplaced items guide you back to them with an audio beacon, and saved rooms are recognized when you return. Every signal travels through the user's choice of sound, speech, and vibration — including a fully audio-free profile for deaf-blind users.

> Built in an 8-week engineering roadmap as a production-grade portfolio project.
> Swift 6 · SwiftUI · ARKit · RealityKit · CoreML/Vision · AVFAudio · CoreHaptics · iOS 17+

---

## Why this exists

Canes and guide dogs are excellent at ground level. They cannot warn about a drop-off two steps ahead in an unfamiliar building, an open cabinet door at head height, or where you left your keys. Modern iPhones carry a LiDAR scanner, a neural engine, and an HRTF spatial-audio renderer — enough hardware to give a blind user a genuine sixth sense indoors. SpatialNav is an attempt to do that with production discipline rather than tech-demo shortcuts.

## Feature overview

| Feature | How it works |
|---|---|
| **Sonar Mode** | 9 rays fan out against the LiDAR scene mesh at 10 Hz; the nearest obstacle plays an HRTF-positioned ping from its real direction — higher and faster as it closes (1200 Hz/0.15 s near → 440 Hz/1 s far) |
| **Drop-off & stairs detection** | Two gravity-aligned floor probes compare ground height ahead; discontinuities past thresholds trigger interruptive warnings. Surface normals distinguish a stair tread from furniture at the same height |
| **Object recognition** | YOLOv8-nano (CoreML, Neural Engine only, 5 fps gated) → each detection's bounding box is raycast into the scene for true world position → temporal confirmation suppresses single-frame ghosts |
| **Item Finder** | Register an item by pointing the camera at it (Vision feature-print + world anchor); a distinct audio beacon and clock-face guidance lead you back |
| **Saved Spaces** | ARWorldMaps compressed (LZFSE) and persisted; relocalization restores your saved rooms — with an honest 10 s watchdog that starts fresh rather than guiding on stale data |
| **Scene description** | On demand: "Caution — drop-off ahead. Chair, 2 meters at 11 o'clock. Nearest obstacle 1.4 meters at 1 o'clock." Composed entirely from already-tracked state, offline, instant |
| **Sensory profiles** | Sound-led, vibration-led, hybrid, or vibration-only (deaf-blind); a first-launch tutorial teaches every signal by playing it; all routing decisions live in one tested policy object |
| **Thermal governor** | Thermal state + Low Power Mode + battery level map to processing tiers with hysteresis; ML frame rate and sonar ray count degrade gracefully — and the degradation is announced, never silent |

## Architecture

MVVM + a framework-free Domain layer, dependency-injected through a single composition root.

```
SpatialNav/
├── App/                  AppContainer (composition root — the only place concrete types are built)
├── Domain/
│   ├── Models/           Pure value types (Obstacle, Hazard, FeedbackEvent, SavedSpace, …)
│   ├── Services/         Protocols only — the DI seams every ViewModel depends on
│   └── UseCases/         Pure, exhaustively-tested policy: sonar sweep, hazard detection,
│                         alert arbitration, feedback routing, tier hysteresis, scene description
├── Services/             Concrete framework owners (the ONLY files importing ARKit/AVFAudio/…)
│   ├── AR/               ARSessionManager (queue-confined ARSession), MeshStore, WorldMapCodec
│   ├── ML/               YOLODetectionService, FeaturePrintService, FrameSampler
│   ├── Audio/            SpatialAudioEngine (HRTF), AudioBeaconPool, SpeechQueue, ToneGenerator
│   ├── Haptics/          HapticEngineService (health-checked CHHapticEngine)
│   └── Persistence/      SpaceStore, ItemStore, SettingsStore (encrypted at rest)
└── Features/             One folder per screen: SwiftUI View + @Observable ViewModel
```

**Concurrency:** Swift 6 language mode, strict data-race safety. ARKit objects never cross an isolation boundary — value snapshots are extracted at the delegate boundary and everything downstream is `Sendable`. Framework owners are actors or queue-confined classes with documented invariants.

**Testability:** ViewModels and use cases see only protocols; 148 unit tests run without a camera, plus an automated accessibility audit (Xcode's `performAccessibilityAudit`) in CI on every push.

## Engineering challenges & solutions

The parts that would have sunk a naive implementation — several found by on-device field testing:

| Challenge | Solution |
|---|---|
| Continuous ML cooks the device | Frame sampler gates inference to ≤5 fps; nano model on Neural Engine only (GPU stays free for rendering); thermal governor downshifts tiers with 30 s upgrade hysteresis |
| ARKit's camera buffer pool starves if frames are retained | One-in-flight inference via actor serialization; streams buffer at most one snapshot; buffers never queue |
| Mesh updates flood the main thread | Session delegate on a dedicated queue; keep-latest coalescing into an actor-backed store, time-gated at 5 Hz |
| **Field finding #1:** pointing the phone up at a desk fired "drop-off ahead" | Floor probes were camera-relative; made them gravity-aligned (elevation measured from the horizon) + floor-plausibility gates + 3-sweep debounce |
| **Field finding #2:** a wardrobe drawer front at step height read as "stairs up" | A vertical face and a stair tread produce identical hit points — position alone cannot distinguish them; raycast surface normals now gate "walkable" judgments (drop-off deliberately stays ungated: warn-first) |
| **Field finding #3:** mirrors detect the user's own reflection as a person | Documented behavior: distance reported is to the mirror surface — information, not noise |
| CHHapticEngine dies silently when AirPods connect | Health-checked before every pattern; reset/stopped handlers mark it dead; rebuilt on demand with one retry |
| Speech collisions ("chair at 2 o'clock" over "DROP-OFF AHEAD") | Priority-arbitrated speech queue — critical interrupts, equal waits, low drops when full; VoiceOver users route through UIAccessibility so VoiceOver arbitrates |
| A blind user can't rescue a stuck relocalization | 10 s watchdog announces "I can't recognize this space" and starts fresh instead of guiding on stale data |
| Contrast failures on the exact users who need contrast | Automated accessibility audit in CI; it has already caught three real issues (secondary-on-fill text, CTA text size, content scrolling behind a floating button) |

## Privacy & security

- **No server. No account. No analytics. No tracking.** The privacy label is "Data Not Collected" — see [PRIVACY.md](PRIVACY.md).
- Camera frames are processed on-device and discarded; nothing is ever stored or transmitted.
- Saved world maps encode the layout of your home, so they're **encrypted at rest** (complete file protection).
- A privacy manifest ships in the bundle; the only declared API category is UserDefaults (app's own settings).

## Testing

```
xcodebuild test -project SpatialNav.xcodeproj -scheme SpatialNav \
  -destination 'platform=iOS Simulator,name=<any iPhone>' -only-testing:SpatialNavTests
```

- 148 unit tests over the Domain layer's pure logic: bearing math, ray geometry, hazard thresholds, alert arbitration, tier hysteresis, speech-queue policy, detection smoothing, persistence round-trips.
- Accessibility audit UI test across onboarding, tutorial, and main screens.
- GitHub Actions runs the suite on every push and pull request.
- Plus three rounds of on-device field testing (see table above — the false-positive fixes each shipped with regression tests encoding the exact field geometry).

## Building & running

1. Open `SpatialNav.xcodeproj` (Xcode 26+), select an iPhone with LiDAR (iPhone 12 Pro or later Pro models, or any iPhone 15 Pro+/16), build and run.
2. The YOLOv8n CoreML model is bundled. To regenerate it: `scripts/convert_yolo_to_coreml.py`.
3. Non-LiDAR iPhones run with reduced obstacle detection (plane-based raycasts); simulators show the unsupported-device screen.

## Roadmap

Doorway detection, breadcrumb guided-return, moved-item re-acquisition via feature-print matching, Siri App Intents ("find my keys"), CloudKit space sync — each deliberately deferred behind a stable, tested core.
