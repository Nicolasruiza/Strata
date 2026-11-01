# Strata for iOS + Apple Watch

The web app in the repo root is the spec (see `../IOS_BRIEF.md` and `../IOS_NOTES.md`).
This folder holds the native port. **Phase 1 (Foundation)** is what exists so far: the
project, the shared logic package and its golden tests. There is no UI yet.

```
ios/
  project.yml            XcodeGen spec (never hand-edit a .pbxproj; Strata.xcodeproj is generated)
  Package.swift          the StrataCore package (iOS 17 / watchOS 10 / macOS 14)
  StrataCore/            models, config, catalog and every ported function (no UI, no HealthKit)
  StrataCoreTests/       golden tests + Fixtures/*.json
  Strata/                iPhone app shell (empty @main, links StrataCore)
  StrataWatch/           watch app shell (empty @main, links StrataCore)
  tools/                 Node scripts that generate the fixtures and the catalog from the JS
```

## How the port is kept honest

* **Golden fixtures come from the JS itself.** `tools/make-fixtures.mjs` loads `core.js`,
  `app.js` and `workout.js` in a Node `vm` with a stubbed DOM (`tools/webctx.mjs`), calls each
  function on varied inputs (empty history, stalled lift, skipped day, missed reps, injury hold,
  4×4 at every phase, sample gaps over 15 s, GPS noise, DST weeks…) and writes inputs + outputs
  to `StrataCoreTests/Fixtures/`. Click handlers are driven through the real event listeners, so
  logic that lives inline in the event wiring is covered too. The Swift tests must match every
  fixture exactly: the returned value, the data left behind, the toasts and the `confirm()` text.
* **The catalog is generated, not typed.** Plans, movement metadata, injuries, focus areas, cues,
  photos and home sessions are emitted from the web source by `tools/make-catalog.mjs` into
  `StrataCore/Catalog.generated.swift`, so a typo can't creep in.
* **Time zones.** Fixtures are generated for `America/Toronto` and `UTC`, with weeks that cross
  both 2026 DST changes (03-08 and 11-01). The date logic works on `YYYY-MM-DD` strings with
  explicit Monday-based weeks and never uses the device locale or `Calendar.firstWeekday`.
* **Config.** `Config.workout` mirrors `WCFG` field for field (a test compares them); the other
  constants that were inline in `core.js` / `app.js` are in `Config` too.
* **Regenerate whenever the JS changes**, then commit the result (CI fails if they differ):

```bash
node ios/tools/make-catalog.mjs && node ios/tools/make-fixtures.mjs
```

Use the Node version pinned in `.github/workflows/ios.yml`; date labels come from its ICU data.

## Running things

```bash
cd ios
swift test                                  # all golden tests, on the Mac
xcodegen generate                           # creates Strata.xcodeproj
xcodebuild build -project Strata.xcodeproj -scheme Strata -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Strata.xcodeproj -scheme StrataWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO
```

## What was ported (Swift name ← JS name)

`Engine` is the web's global state (`DB`, `profile`, `PLAN`…) as one value. Methods that change
data are `mutating`; what the web did with `toast()` is returned as a string, and what it did with
`confirm()` is a separate `…Prompt` check, so the UI decides how to present them.

| Area | Swift | JS |
|---|---|---|
| Plans | `PlanBuilder.genPlan/planFor/stdFor/build`, `Engine.setActivePlan`, `exById`, `Catalog.meta(of:)` | `genPlan`, `planFor`, `stdFor`, `setActivePlan`, `mkEx`, `appendEx`, `applyBump`, `idsForInjury`, `metaOf`, `exById` |
| Progression | `wOf`, `progressedWeight`, `loEnergyW`, `lastOf`, `volOf`, `requiredItems`, `sessionItems` | same names |
| Holds / injuries | `weeklySets`, `costOf`, `patternsLost`, `applyInjury`, `releaseInjury`, `injuryPrompt` | `weeklySets`, `costOf`, `patternsLost`, `applyInjury`, `releaseInjury` |
| Week | `weekPlan`, `officeDays`, `weekStats`, `streak`, `liftSlots`, `slotDone`, `nextDay`, `gate`, `homeKey`, `minutesFor`, `ringsLine`, `weekHeadline`, `nextCard`, `historyItems`, `topSets`, `progressPoints`, `progressWeeks` | same names (`weekHeadline`/`progressPoints`/`progressWeeks` are the inline computations in `todayView`/`progressView`) |
| Cardio | `rcHR`, `rcPhases`, `rcMinutes`, `rcDefaultIntervals`, `hrMax`, `zoneOf`, `zoneRange`, `cardioPlan`, `lastActFor`, `recentCardio`, `phaseAt`, `hardDone`, `cardioStats`, `startCardio`, `takeSample`, `endCardio` + `recordHealthResult` (= `completeCardio`), `logCardio` | same names |
| Strength | `liftList`, `shownEx`, `curIdx`, `setsOf`, `progOf`, `exState`, `nextUp`, `woBlocks`, `trendOf`, `restFor`, `begin`, `openEx`, `logWoSet`, `adjustReps`, `undoSet`, `adjustWeight`, `addExtraSet`, `warmupOptions`, `addWarmup`, `toggleWarmup`, `removeWarmup`, `markBusy`, `completeExercise`, `applySwap`, `endSession`, `sessionSummary` | same names, or the inline click handlers in `workout.js` |
| Can't train | `skipToday`, `undoSkip`, `homeDone`, `homeKey`, catalog `skipWhy` / `home` | `data-why`, `undoSkip`, `homeDone` handlers, `SKIP_WHY`, `HOME` |
| Data | `AppData` (same JSON schema as the web `DB`), `applyImport`, `exportData`, `importPrompt`, `Engine.newProfile`, `setGender` | `defaultDB`, `freshDB`, `applyImport`, export button, `newProfile`, `setGender` |
| Adapters | protocols `Sensors`, `HealthService` (same shapes) | `Sensors`, `Health` |

**Not ported:** `sensors.demo.js` (a web testing tool, in any form), `liftLogLocal` (reads browser
`localStorage`), the unused `applyAccent`/`badge`/`cycleDone`/`cycleDayNum`/`newId`/`baselineSets`/
`costHTML`/`W_SCREENS`, the old one-at-a-time lift screen that `workout.js` overrides, and the old
standalone 4×4 timer that `main` no longer reaches.

## Not in phase 1

Screens and `ios/PARITY.md` (phase 2), HealthKit (phase 3), the watch workout session and Live
Activity (phase 4), TestFlight (phase 5). The SwiftUI layout geometry that the web draws inline
(`lineSVG`, `barSVG`, ring paths) is view code and is ported with the screens; the numbers behind
it (`progressPoints`, `progressWeeks`, `weekStats`) are already here and tested.
