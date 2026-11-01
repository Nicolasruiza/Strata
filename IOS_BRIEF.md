# Brief for Claude Code: build Strata for iOS + Apple Watch

## 0. Source of truth

The web app in this repo **is the spec**. Port it 1:1 to native: same screens, order, copy, colours, rules and numbers. Don't redesign, simplify, rename or "improve" anything. If the HTML/JS doesn't answer a question, **stop and ask**. Don't guess.

Read these first, completely, before writing any code:

| File | What it is |
|---|---|
| `core.js` | Plans (PLAN_NR, PLAN_SA…), progression, injuries/holds, weekly sets, HR helpers (`rcHR`, `rcPhases`), storage schema (`defaultDB`) |
| `app.js` | Every screen except workout mode: Today, week strip, rings, preview, jumps, done, history, progress, settings, onboarding, "Can't train today" + home sessions |
| `workout.js` | Workout mode: cardio picker, live cardio, between-blocks sheet, strength overview + exercise focus, lock, `WCFG`, `Sensors` and `Health` adapters, `cardioStats` |
| `style.css` | Design tokens (colours, radii, type sizes). Port them as a SwiftUI theme. |
| `IOS_NOTES.md` | Screen-by-screen flow, rules to keep, simulated → real API table, data schema |
| `img/`, `icons/` | Assets: reuse them, don't regenerate |

## 1. Hard rules

1. **No dummy, mock, placeholder, sample or hard-coded data in the app.** No fake heart rate, fake history, fake "Saved to Apple Health", fake watch status, or seeded workouts. If a value isn't available, show the empty state the web app shows ("—", "Waiting for GPS", "Add your age in Settings to see zones").
2. **`sensors.demo.js` is a web testing tool. Do NOT port it**, in any form, to any target. Test data belongs only in unit-test fixtures and SwiftUI previews, never in the app target.
3. **Every number comes from config.** Port `WCFG` (workout.js) and the plan/progression constants (core.js) into one `Config` type. No magic numbers in views.
4. **Same data schema.** `DB` (see `defaultDB`, `IOS_NOTES.md` › Data) becomes `Codable` structs with the same field names, so a JSON export from the web app imports into iOS unchanged.
5. **Logic is ported, not rewritten.** Each JS function that computes something (list below) gets a Swift twin with the same inputs and outputs, proven by golden tests (section 4).
6. **Don't hand-edit `.pbxproj`.** Use XcodeGen (`ios/project.yml`).
7. **One phase per PR.** List what you ported and any question you had to ask.

## 2. What to port as-is (logic exists in JS)

Port these with identical behaviour:

- **Plans and progression:** `planFor`, `setActivePlan`, `requiredItems`, `sessionItems`, `wOf`, `progressedWeight`, `loEnergyW`, `endSession` (progression rules), holds/injuries, `weeklySets`.
- **Week logic:** `weekPlan`, `officeDays`, `liftSlots` (including skipped days), `weekStats`, `streak`, `nextDay`, `slotDone`.
- **Cardio:** `rcHR`, `rcPhases`, `rcMinutes`, `rcDefaultIntervals`, `cardioPlan`, `lastActFor`, `phaseAt`, `hardDone`, `zoneOf`, `zoneRange`, **`cardioStats`** (time-weighted avg, max, time in zones, elevation gain with noise filter, gap rule).
- **Strength workout mode:** `woBlocks`, `exState`, `nextUp` (busy rule), `trendOf`, `openEx` (order tip), `logWoSet`, warm-up options, extra sets, machine busy, swap.
- **Can't train:** `SKIP_WHY`, `HOME`, `homeKey`, the skip effect on `liftSlots`.
- **All copy strings,** exactly as written.

## 3. What to build from scratch (simulated or impossible on the web)

| Web prototype | Build natively | Notes |
|---|---|---|
| `Sensors` adapter (web: GPS altitude only, no HR) | `Sensors` protocol with `start(session)`, `stop()`, `read(t) → {hr, alt}`, `hrSource`. iPhone implementation receives HR from the watch; altitude from `HKWorkoutRouteBuilder` / CoreLocation, or `CMAltimeter`. | Keep `read()`'s shape so `cardioStats` ports unchanged. |
| `Health` adapter (web: always `started:false`, `saved:false`) | `HealthService`: authorization, `startWatchApp(with: HKWorkoutConfiguration)`, saving via the watch's `HKLiveWorkoutBuilder.finishWorkout()`, reading resting HR and steps. | Request only the types we use. Show the real result in the UI. |
| No watch app | **watchOS target "Strata Watch"**: runs `HKWorkoutSession` + `HKLiveWorkoutBuilder`, streams HR (and later route) to the phone with mirrored sessions (`startMirroringToCompanionDevice`, iOS 17+/watchOS 10+) or `WCSession`. Minimal UI: HR, zone, elapsed, End. | Third-party apps can't start Apple's Workout app. Our own watch app is the only way. |
| `render` wrapper lock + hidden tabs | Workout as `.fullScreenCover` + `interactiveDismissDisabled(true)`; only Complete / Discard leave. | |
| `lockScreen()` wake lock | `isIdleTimerDisabled` during workouts + Live Activity (ActivityKit) showing HR / phase / elapsed. | |
| `cue()` beep | Watch haptic + iPhone haptic at 4×4 phase changes and end of rest. | |
| `localStorage` | JSON file (same schema) in the app container, written atomically. Export/import JSON in Settings, same as web. | |
| Office-day steps typed by hand | Read daily step count from HealthKit for office days. Keep manual entry as a fallback. | |
| Activity type mapping | `CARDIO_ACTS[*].hk` → `HKWorkoutActivityType` + `locationType` / `swimmingLocationType`. Strength = `.traditionalStrengthTraining`. | |

## 4. How to avoid porting mistakes

1. **Golden tests from the JS.** Write `ios/tools/make-fixtures.mjs`, which loads `core.js` / `app.js` / `workout.js` in Node (stub `document` and `localStorage`), runs every function in section 2 on varied inputs (empty history, stalled lift, skipped day, missed reps, injury hold, 4×4 at each phase, sample gaps > 15 s, GPS noise) and writes inputs + outputs to `ios/StrataCoreTests/Fixtures/*.json`. Swift unit tests must match every fixture exactly. Regenerate fixtures whenever the JS changes.
2. **Shared logic package.** `StrataCore` is a Swift package with no UI or HealthKit, holding models, config and all ported logic, used by both the iPhone and watch targets. All golden tests live here.
3. **Screen parity checklist.** For every screen, write `ios/PARITY.md` with the elements in the HTML (top to bottom, with copy) and tick each one off in SwiftUI. Add SwiftUI previews fed only by test fixtures.
4. **Build in CI, since there's no local Mac.** A GitHub Actions `macos` runner runs XcodeGen, `xcodebuild build test` for both targets, and on `main` uploads to TestFlight with an App Store Connect API key. Every PR must be green before it's done.
5. **Ask, don't assume,** when you find any behaviour the web app doesn't define.

## 5. Phases (one PR each)

1. **Foundation:** XcodeGen project (iOS 17+, watchOS 10+), `StrataCore` with models + config + ported logic + golden tests, CI build/test. No UI yet.
2. **iPhone app parity without HealthKit:** every screen from `app.js` and `workout.js`, local JSON storage, import of a web export. HR shows "—" exactly like the web.
3. **HealthKit on iPhone:** authorization, steps for office days, saving workouts, the real `HealthService` result in the UI.
4. **Watch app:** workout session, HR stream to the phone, start from the phone after the 3-2-1 countdown, Live Activity, haptics.
5. **TestFlight:** signing via API key, upload from CI.

## 6. Decisions already made

- Native SwiftUI, not React Native/Expo: the watch app and live workouts need native code.
- Code lives in this repo under `ios/`, next to the web spec.
- UI copy in English, same as the web app.
- The web app stays live. It's the place to prototype changes first, which then get ported.
