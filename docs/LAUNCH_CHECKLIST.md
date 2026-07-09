# Launch Checklist — August 2026

Everything is prepared; this is the mechanical sequence once the Apple
Developer Program membership is active. Realistic total: **launch submitted
within 2–3 days of enrolling**, most of it waiting on Apple.

## Before enrolling (can do today, zero cost)

- [x] App icon finished and installed in `Assets.xcassets/AppIcon.appiconset` (light/dark/tinted, no alpha; vector sources in `design/icon/`)
- [ ] Record the demo video for App Review (shot list in APP_STORE_KIT.md); upload unlisted to YouTube; paste link into the Review Notes section of APP_STORE_KIT.md
- [ ] Capture the 6 screenshots on device (shot list in APP_STORE_KIT.md)
- [ ] Run the Instruments pass (Time Profiler + 20-min thermal soak) and stash screenshots for the README
- [ ] Final on-device regression walk: onboarding tutorial → sonar → drop-off warning → item round trip → space save/reload → pause/describe
- [ ] Confirm GitHub Actions CI is green on `main`

## Day 1 — enrollment day

- [ ] Enroll at developer.apple.com ($99/year; individual enrollment is usually approved within 48 h, often same-day)
- [ ] Xcode → Settings → Accounts: sign in; select the new team in Signing & Capabilities (replaces the personal team `K8FKWBYV9S`)
- [ ] Verify automatic signing produces a distribution-capable profile (Product → Archive should succeed)

## Day 1–2 — App Store Connect setup (~1 hour, all answers pre-written)

- [ ] appstoreconnect.apple.com → My Apps → "+" → New App: name/bundle ID/SKU from APP_STORE_KIT.md
- [ ] Paste description, subtitle, promotional text, keywords
- [ ] Privacy: answer "No" to data collection → label becomes **Data Not Collected**; set privacy policy URL
- [ ] Age rating questionnaire: all "No" → 4+
- [ ] Upload screenshots
- [ ] App Review notes: paste from APP_STORE_KIT.md (with demo video link)
- [ ] App Review contact info: your name/email/phone

## Day 2 — build upload

- [ ] Bump nothing (1.0 / build 1 already set) — Product → Archive → Distribute → App Store Connect → Upload
- [ ] Export compliance question at upload: uses only exempt/OS encryption (answers in APP_STORE_KIT.md)
- [ ] Wait for processing (~15–30 min), fix any asset validation emails if they appear

## Day 2–7 — TestFlight (strongly recommended before public release)

- [ ] Internal testing: add yourself; install via TestFlight app; one full regression walk on the TestFlight build (it is signed differently from Xcode builds — verify camera permission flow and file protection behave)
- [ ] External testing (optional but valuable): create a group, invite 3–5 testers — ideally at least one VoiceOver user; local blind-community organizations often have tech-interested members happy to beta test. External TestFlight requires a lightweight beta review (usually <24 h)
- [ ] Fold in any feedback that's quick; anything bigger goes to 1.1

## Submission

- [ ] Select the build on the version page → Add for Review → Submit
- [ ] Review typically takes 1–3 days. Accessibility apps with clear review notes + demo video usually pass first try; the most likely rejection reason is a reviewer without a LiDAR device not understanding the unsupported screen — the review notes preempt this
- [ ] If rejected: read the exact clause, respond in Resolution Center (the demo video link answers most camera-app questions), resubmit — turnaround on resubmission is usually <24 h

## Launch day

- [ ] Release (manual release recommended: submit with "Manually release this version" so you control the moment)
- [ ] Update README with the App Store badge/link
- [ ] Portfolio: add the App Store link + Instruments screenshots to the README case study

## Known post-launch backlog (v1.1 candidates)

Doorway detection · breadcrumb guided-return · moved-item re-acquisition ·
Siri App Intents · CloudKit space sync · localization (String Catalogs are
already in place)
