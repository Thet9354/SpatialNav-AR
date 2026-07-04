# App Store Submission Kit

Everything to paste into App Store Connect in August. Written now so launch day
is mechanical. Companion document: [LAUNCH_CHECKLIST.md](LAUNCH_CHECKLIST.md).

---

## App identity

| Field | Value |
|---|---|
| App name | **SpatialNav — Indoor Guide** (30-char limit; "SpatialNav" alone if taken names force it) |
| Subtitle | **Sonar for indoor navigation** (30-char limit) |
| Bundle ID | `com.thetpine.AR.SpatialNav` (already set in the project) |
| SKU | `spatialnav-001` |
| Primary category | Navigation |
| Secondary category | Utilities |
| Age rating | 4+ (answer "No" to every content question) |
| Price | Free |

## Promotional text (170 chars, editable without review)

> Walk unfamiliar indoor spaces with confidence: obstacles ping from their real direction, drop-offs warn before you reach them, and lost items call you back to them.

## Description

> SpatialNav turns your iPhone into a spatial-awareness assistant for blind and low-vision users.
>
> Hold the phone facing forward and walk. Using the LiDAR scanner and on-device intelligence, SpatialNav senses the space around you and speaks your language — sound, speech, vibration, or any mix you choose.
>
> SONAR MODE
> Obstacles ping from their true direction in 3D audio, faster and higher as they get closer — like a parking sensor for walking. Best with headphones.
>
> HAZARD WARNINGS
> Drop-offs and stairs trigger unmistakable warnings — two heavy thuds and a rumble mean stop. A safety-first design warns early and never silently degrades.
>
> KNOWS WHAT THINGS ARE
> On-device object recognition tells you what's ahead and where: "keyboard, 1 meter at 12 o'clock." Ask "Describe" anytime for a spoken snapshot of your surroundings.
>
> FIND MY THINGS
> Point the camera at your keys once. Next time you lose them, follow the beacon — a heartbeat tick that plays from where they are.
>
> REMEMBERS YOUR SPACES
> Save a room and SpatialNav recognizes it when you return, with your saved items and their places.
>
> YOURS, PRIVATELY
> No account. No server. No data collected — the camera is processed on your device and discarded. Saved rooms are encrypted at rest. Works entirely offline.
>
> BUILT ACCESSIBILITY-FIRST
> Full VoiceOver support, a first-launch tutorial that teaches every sound and vibration, a vibration-only profile for deaf-blind users, Dynamic Type, and distances spoken in meters, feet, or your own steps.
>
> Requires an iPhone with a LiDAR scanner (iPhone 12 Pro or later Pro models, iPhone 15 Pro and all iPhone 16 models) for full obstacle detection. Other iPhones run with reduced sensing.
>
> SpatialNav assists your awareness — it does not replace a cane, guide dog, or orientation and mobility training.

## Keywords (100 chars, comma-separated, no spaces)

```
blind,low vision,accessibility,navigation,indoor,lidar,obstacle,sonar,voiceover,assistive,haptic
```

## Privacy section answers (App Store Connect questionnaire)

- "Do you or your third-party partners collect data from this app?" → **No**
- Resulting label: **Data Not Collected**
- Privacy policy URL: `https://github.com/Thet9354/SpatialNav-AR/blob/main/PRIVACY.md`
  (or a GitHub Pages URL if preferred — content already written in PRIVACY.md)

## Export compliance

- "Does your app use encryption?" → **Yes** (uses only iOS's standard/exempt encryption: HTTPS none, data-at-rest file protection)
- "Does your app qualify for any of the exemptions?" → **Yes** — it only uses encryption within Apple's operating system
- No documentation upload required. (Optionally add `ITSAppUsesNonExemptEncryption = NO` to the Info.plist later to skip the question per-build.)

## App Review notes (paste verbatim into the Review Notes field)

> SpatialNav is an accessibility app for blind and low-vision users. It uses the camera + LiDAR to detect obstacles and hazards in real time and communicates them through spatial audio, speech, and haptics.
>
> IMPORTANT FOR REVIEW:
> 1. The app requires a physical iPhone with LiDAR for full functionality (iPhone 12 Pro+, 15 Pro+, or any iPhone 16). On other devices it runs with reduced obstacle detection; on simulator it shows an unsupported-device screen by design.
> 2. Camera permission is required for all functionality — the app is a real-time sensing assistant and has no meaningful function without it.
> 3. All processing is on-device. No data is collected or transmitted; there is no server component.
> 4. A demonstration video of the core features (sonar pings, drop-off warning, object recognition, item finding) is available here: [ADD DEMO VIDEO LINK — unlisted YouTube]
> 5. To test quickly: complete onboarding (any feedback style), allow camera, then walk toward a wall — you will hear accelerating pings and see the obstacle distance on the HUD. Tap "Describe" for a spoken scene summary.

## Screenshots (6.9" required set — iPhone 16 Pro Max or 16 Plus size class)

Shot list (portrait, capture on device via Xcode or screenshots + marketing frames):

1. **Hero**: main screen at a desk with HUD showing "keyboard · 1.0 m at 12 o'clock", caption: *"Hears what you can't see."*
2. **Hazard**: red "Caution — drop-off ahead" banner visible, caption: *"Warns before the edge."*
3. **Tutorial**: "Learn the Signals" screen, caption: *"Teaches you its language first."*
4. **Item finding**: guidance banner "Keys · 2.3 m at 10 o'clock", caption: *"Your things, calling you back."*
5. **Settings/profiles**: feedback style picker, caption: *"Sound, speech, vibration — your mix."*
6. **Scan overlay**: mesh visualization on, caption: *"Show a companion what it senses."*

Accessibility note: write captions into the screenshot images at large size, high contrast.

## App Preview video (optional but high-impact, 15–30 s)

Storyboard: hold phone walking down a hallway → pings accelerate approaching a
wall (visualize with on-screen waveform) → drop-off banner + spoken warning at
a step → point at chair, HUD labels it → "Describe" spoken summary → tagline
card: "SpatialNav. Sonar for indoor navigation." Record device screen +
external phone audio so reviewers hear the spatial pings.

## App icon (needed before archive — user task)

- 1024×1024 PNG, no transparency, no rounded corners (iOS masks it).
- Concept suggestion: concentric sonar arcs radiating from a small person/phone
  silhouette, white on deep blue (#0A3D91-ish), bold and legible at 60 px.
  High contrast — the icon should itself be low-vision friendly.
- Drop into `SpatialNav/Assets.xcassets/AppIcon.appiconset` (single 1024 slot).
