# Strata · Workout mode → iOS port notes

The HTML/JS in this repo is the **source of truth**. Port every screen 1:1 to SwiftUI: same layout, copy, order and rules. Don't redesign. Anything simulated in the browser is marked `IOS:` in `workout.js`. This file lists what replaces each simulated part.

## Flow

1. **Today** → `Start` on a heart day, or `Cardio first` / `Start cardio` on other days → **Pick activity**.
   On a strength day, `See workout` → preview → `Start` goes straight to strength. There's no activity menu.
2. **Pick activity** (`pickView`): the cardio menu only lists cardio.
   - Recommended card comes from today's plan (`cardioPlan()`): 4×4 → treadmill, Zone 2 → treadmill, walk/office → walk, lift/rest day → elliptical warm-up.
   - Recent: last 2 distinct activities from history.
   - All: outdoor bike, indoor bike, walk, elliptical, rower, swim.
   - **Mode follows the plan, the activity is the equipment.** A 4×4 day on an outdoor bike is still a 4×4 with phases.
3. **Countdown** 3-2-1 (`countdown()`) → the Apple Watch starts → full-screen workout.
4. **Cardio in progress** (`cardioView`): heart rate + zone, 4×4 phase card (4×4 days only), time in zones Z1–Z5, elapsed, elevation (outdoor activities) or average HR (indoor), Watch status. The only exits are **Discard** (confirm) and **Complete**.
5. **Complete** → summary (`cDoneView`) + **between-blocks sheet** (`blockSheet`): `Add block: Strength · <next lift>` (recommended, hidden if a lift was already logged today) or `End session`.
6. **Strength overview** (`overviewView`): full screen, grouped Basics → Compound → Isolation (if time), each row Done / x of n / Busy / Next. Legs days show the jumps warm-up row on top. Exits: **Discard** or **Complete** (`endSession`).
7. **Exercise in focus** (`focusView`): photo, block tag ("Compound 1 of 2"), last time + trend chip, rest timer, today's weight with −/+ and plate math, warm-up rows, set rows (log the current set with a reps stepper, undo the last), `+ Set`, `+ Warm-up`, form video, swap, **Machine busy**. The back button returns to the overview, never out of the workout.
8. After strength `Complete` → existing summary, with `Add cardio` to chain a cardio block.

## Rules to keep

- **Lock:** while `DB.active` (strength) or `DB.live` (cardio) exists, the tab bar is hidden and any other screen redirects back to the workout (`render` wrapper).
- **Order guidance:** opening an exercise from a later block while an earlier required block has unfinished, not-busy lifts shows "Tip: finish Basics before Compound". It's a hint and doesn't block you.
- **Machine busy:** marks the lift busy for 3 min and jumps to the next unfinished lift in the same block. If none is left, it offers swap alternatives.
- **Warm-up sets:** empty bar / 50% / 70% of today's weight. They never count toward progression.
- **Extra sets** count toward the logged entry.
- **Trend chip** (`trendOf`): First time · Progressing (weight went up last session) · On track (all reps hit last time) · Behind (missed reps) · Stalled (same weight 3+ sessions and still missing reps) · On hold (injury hold).
- **Multi-block sessions:** each block is saved separately (a cardio entry + a lift session), so each fills its own ring. A cardio block under 20 min on a non-heart day doesn't close a Heart session.
- **Timers are timestamp-based:** the workout keeps counting in the background and while the phone is locked.

## Simulated → real API

| Prototype | iOS / watchOS |
|---|---|
| `countdown()` toast "Apple Watch · … started" | `HKHealthStore.startWatchApp(with: HKWorkoutConfiguration)` launches the **Strata watch app** (watchOS target required). The watch runs `HKWorkoutSession` + `HKLiveWorkoutBuilder`. You can't start Apple's own Workout app from a third-party app. |
| `simHR()`, `liveStats()` heart rate + zones | Live `HKQuantityType(.heartRate)` from the builder, relayed watch → phone with `WCSession` (or mirrored sessions, iOS 17+ `startMirroringToCompanionDevice`). Zones: keep the %HRmax bands in code (Z1 < 60, Z2 60–70, Z3 70–80, Z4 80–90, Z5 > 90), with HRmax = 208 − 0.7 × age. |
| Elevation `+m` | `HKWorkoutRouteBuilder` (CoreLocation altitude) on outdoor workouts, or `CMAltimeter` relative altitude. |
| `CARDIO_ACTS[*].hk` | `HKWorkoutActivityType` + `locationType` to set in `HKWorkoutConfiguration`. |
| `completeCardio()` → `logCardio` | `builder.endCollection` + `finishWorkout()` on the watch saves the `HKWorkout` to Apple Health with HR samples, energy and route. Keep the Strata log entry too (type, act, min, avgHR, maxHR, zones). |
| Strength workout | `HKWorkoutConfiguration(activityType: .traditionalStrengthTraining)` started the same way. Sets and reps stay in Strata. |
| Lock (`render` wrapper, hidden tabs) | Present the workout as `.fullScreenCover` with `interactiveDismissDisabled(true)`. No tab bar. |
| `lockScreen(true)` wake lock | `UIApplication.shared.isIdleTimerDisabled = true` during the workout + Live Activity (ActivityKit) for the lock screen. |
| `cue()` beep/vibrate at 4×4 phase changes | Watch haptics `WKInterfaceDevice.current().play(.notification)` + `UINotificationFeedbackGenerator`. |
| `localStorage` (`DB`) | SwiftData or a JSON file in the app container. Keep the same schema so exports stay compatible. |

## Data added by this feature

- `DB.live` = running cardio `{act, mode:'4x4'|'z2'|'free', n, slot, started, date}`
- `DB.cardio[]` entries gain `act, avgHR, maxHR, zones[5], elev?`; new type `cardio` for cardio outside a heart day.
- `DB.active` gains `view:'list'|'focus'`, `exT{id:ts}` (exercise timer), `extra{id:n}` (extra sets), `warm{id:[{w,r,done}]}`, `busy{id:ts}`, `cd` (countdown shown).
