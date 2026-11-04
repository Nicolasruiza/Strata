# Strata watchOS companion — design specification

Status: design handoff, watchOS 10+, 41 mm and 49 mm. The iPhone remains the source of truth.

## Foundations

| Token | Value | Use |
|---|---:|---|
| Canvas 41 mm | 176 × 215 pt | Layout baseline |
| Canvas 49 mm | 205 × 251 pt | Large layout; never stretch from 41 mm |
| Safe inset | 8 pt / 10 pt | 41 mm / 49 mm |
| Background | `#0E1018` | All opaque screens |
| Surface | `#FFFFFF` at 8% | Cards, secondary controls |
| Surface pressed | `#FFFFFF` at 14% | Press feedback |
| Border | `#FFFFFF` at 12% | One physical pixel |
| Primary text | `#F4F5F8` | Main values and labels |
| Secondary text | `#A9AEBD` | Supporting information |
| Dim text | `#6E7385` | Tertiary and AOD content |
| Strength | `#9C8CFF` | Strength actions and progress |
| Strength deep | `#7C6CF0` | Strength gradients |
| Cardio | `#FF6B4A` | Heart, zone and interval state |
| Bone | `#4ADE80` | Jump/bone state |
| Destructive | `#FF5D5D` | Cancel only |
| Font | Inter 400–800 | Fixed sizes; tabular figures for all numbers |

Buttons have a 44 pt minimum hit height, 14 pt radius, and 8 pt minimum separation. Full-width actions sit 8/10 pt from the screen edge. The timer toolbar button is 36 × 36 pt visually and 44 × 44 pt interactively.

Images use the iPhone catalog's exact exercise photo. Crop with `scaledToFill`, centered on the subject. Apply a vertical overlay from `#0E1018` at 65% at the top to 75% at the bottom, plus a uniform 10% black wash. If contrast still fails, increase only the local lower gradient; never alter the text color.

## Responsive type and spacing

Values are `41 mm / 49 mm` in points.

| Element | Size | Weight | Color | Position and behavior |
|---|---:|---:|---|---|
| Screen eyebrow | 10 / 11 | 700 | Secondary or accent | Uppercase, tracking 1.2, one line |
| Exercise title | 17 / 19 | 700 | Primary | Top-left, maximum two lines |
| Large target | 42 / 48 | 800 | Primary | Center, tabular figures, one line |
| Target unit | 19 / 21 | 700 | Primary | Baseline or next line when space requires |
| Secondary value | 28 / 32 | 800 | Primary | Load, elapsed, or next target |
| Body | 13 / 14 | 500 | Secondary | One or two lines only |
| Metadata | 11 / 12 | 600 | Secondary | Truncate tail after one line |
| Button label | 16 / 17 | 700 | `#0E1018` on accent | Centered |
| Primary button | 48 / 52 high | — | Accent fill | Full width at bottom |
| Chip | 26 / 28 high | 11 / 12, 700 | Accent text/fill | Capsule, horizontal padding 10 |
| Screen stack gap | 6 / 8 | — | — | Collapse to 4 pt before reducing type |

## Screen and state specification

### Idle — plan available

- Top row: `TODAY` and the global timer button.
- Main line: plan name, e.g. `Strength · A`, 24/28 pt, weight 800, maximum one line.
- Detail: exercise count and estimated duration from the phone.
- `Start` is the only primary action. It sends a start request; the phone starts the HealthKit workout and returns authoritative session state.
- Never derive a plan locally or show cached data after its `validUntil` time.

### Idle — empty/disconnected

- Title: `No plan yet`.
- Message: `Open Strata on your iPhone`.
- Do not show Start, targets, estimates, or sample data. The standalone timer remains available.
- If stale data exists, show the empty state and a small `Last synced …` line only when the phone supplied a timestamp.

### Strength — current set

- Full-bleed exercise image and overlay. Title and `SET n OF total` at top; timer button top-right.
- Editable actual reps starts equal to target reps but is explicitly an unsaved draft. Center shows `[−] 10 [+]`; buttons change one rep. Crown changes reps by one detent and gives `.click` at each accepted increment.
- Load appears below, e.g. `190 lb`. Tapping load focuses it; crown then changes by the phone-provided `loadIncrement` (never assume 5 lb). Focus ring is violet. Tap reps to return crown focus.
- Last-time line is supplied verbatim as structured sets and formatted on watch. Hide the entire line when absent; do not show a placeholder.
- `Done` sends actual reps and load with an idempotency key. Disable it and show a compact spinner until acknowledged. On acknowledgement, play set-done haptic and show rest or the next set. On timeout, keep the draft and offer Retry.
- Horizontal swipe changes exercise. Crown changes exercises only when no numeric editor is focused. Previous/next navigation requests the phone to move the current pointer; watch does not commit a new current exercise itself.

### Strength — always-on

- Remove the photo and all buttons. Background is black; reduce nonessential color saturation and opacity.
- Keep exercise title, set progress, target reps, and load. Target remains at least 38/44 pt.
- Update no more often than once per minute except when the system grants an active workout refresh. Restore interactive state on wrist raise.

### Timer picker

- Opens modally from the timer button on every screen. Two crown-selectable columns: minutes `00…99`, seconds `00…59`; seconds step by 5 by default, 1 when the user slows the crown.
- Timed exercises prefill `durationSeconds`; otherwise restore the last manually used duration. Presets are product configuration from the phone, with fallback local presets 0:30, 1:00, 1:30 only for the standalone timer.
- `Start` is disabled at 00:00. Close returns without changing workout state.

### Timer count-in, running, paused, finished

- Count-in is exactly 3, 2, 1. Numeral 72/84 pt with a light tick at each change. Start timer at the monotonic deadline, not after animations complete.
- Running uses a 6 pt circular progress ring and 42/50 pt remaining time. Show exercise name and original duration. Pause is one tap; Cancel requires a confirmation sheet so accidental touches do not discard elapsed work.
- Paused freezes the monotonic calculation. Resume and Cancel each retain a 44 pt hit target.
- At zero, play the timer-finished pattern and permitted sound. For an exercise timer, show `Log set`; for standalone use, show `Done`. Logging sends the same `setDone` payload as the strength screen.
- Background/resume behavior uses an absolute `endsAt` plus accumulated paused duration, never decrementing a counter on a repeating timer.

### Rest

- 96/112 pt diameter ring, 6 pt stroke, with remaining time 36/42 pt in the center.
- `NEXT` card contains the next exercise plus target reps/load/duration. All values come from the phone.
- `Skip` ends rest and requests the next set in one tap. Natural completion plays the rest-finished haptic and advances automatically.
- If the phone changes the plan during rest, replace the next card and countdown from the new authoritative snapshot.

### Cardio

- Heart rate is 56/66 pt, weight 800, tabular. Use `—` whenever no sample is available; never retain a stale number beyond 10 seconds without visually marking it stale.
- Zone chip uses the zone color and phone-supplied zone index/name. Elapsed time is 30/34 pt.
- For 4×4, phase chip is `HARD|EASY · n OF 4`, remaining phase time is the primary number, and heart rate/zone is secondary. Phase deadlines come from the session snapshot. Play phase-change haptic at each boundary.
- No-HR state keeps elapsed/phase timing active and shows `HEART RATE UNAVAILABLE`.

### Cardio and timer always-on

- Keep only the key number, phase/zone label, and elapsed or remaining time. Hide actions and decorative glow. Use primary text at 55% and accent at 45%; black background. Recalculate from absolute timestamps when the display refreshes.

## Haptic map

| Event | watchOS implementation | Meaning |
|---|---|---|
| Set done | `WKInterfaceDevice.current().play(.success)` | Short positive acknowledgement, only after phone acknowledgement |
| Count-in tick | `.click` once at 3, 2, and 1 | Light cadence tick |
| Timer finished | `.notification`, then `.notification` after 220 ms | Strong double alert; optional short sound when allowed |
| Rest finished | `.start` | Rising transition into work |
| Cardio phase change | `.directionUp` entering Hard; `.directionDown` entering Easy | Direction communicates intensity change |
| Crown numeric step | `.click` subject to system throttling | Confirms accepted rep/load change |

Do not play haptics when receiving duplicate messages. Sound respects silent mode and system policy; haptic behavior remains the primary signal.

## Data ownership and transport

The phone owns plan selection, exercise order, targets, history, workout lifecycle, HealthKit persistence, and the authoritative log. The watch owns only current UI drafts, transient timer presentation, and sensor display. Each state snapshot includes `sessionID`, monotonic `revision`, `sentAt`, and `validUntil`. Ignore an older revision. Persist the latest acknowledged snapshot and unacknowledged commands for reconnect recovery.

Use mirrored `HKWorkoutSession` data for messages while a strength/cardio workout session is active. Use `WatchConnectivity` for plan preview, pre-workout state, recovery after disconnection, and queued user commands when no mirrored session is available. Both transports carry the same versioned Codable envelope.

### Phone → watch messages

| Type | Required payload |
|---|---|
| `protocolHello` | protocol versions, app build, capabilities |
| `todayPlanSnapshot` | plan ID/name, modality, count, estimate, `validUntil` |
| `workoutStateSnapshot` | session ID, revision, mode, lifecycle state, current exercise/set, navigation bounds |
| `exerciseSnapshot` | exercise ID/name, image asset key/version, set index/count, target reps/load/unit, `loadIncrement`, last sets, optional `durationSeconds`, rest seconds |
| `restStarted` | rest ID, `endsAt`, next exercise snapshot |
| `cardioSnapshot` | activity, startedAt, latest HR/sample time, zone definitions/current zone, optional interval plan/current phase/phase endsAt |
| `timerConfiguration` | preset seconds, optional exercise duration |
| `commandAcknowledgement` | command ID, accepted/rejected, authoritative revision, optional error |
| `workoutEnded` | session ID, outcome, saved flag |
| `syncRequired` | reason; watch responds with state request |

### Watch → phone messages

| Type | Required payload |
|---|---|
| `requestState` | known session ID/revision and reason |
| `startWorkout` | plan ID, command ID |
| `setDone` | session/exercise/set IDs, actual reps, actual load/unit, optional elapsed duration, command ID, completedAt |
| `skipRest` | session/rest IDs, command ID |
| `navigateExercise` | session ID, direction or destination exercise ID, command ID |
| `timerEvent` | timer ID, exercise/set IDs when applicable, started/paused/resumed/cancelled/finished, timestamps |
| `endWorkout` | session ID, command ID |
| `protocolHello` | supported versions, app build, capabilities |

Commands are at-least-once delivery and must be idempotent by `commandID`. A command is not visually committed until acknowledged. The phone replies with a full or delta snapshot after every accepted mutation.

## State and failure rules

- **Phone unreachable before workout:** disconnected idle; standalone timer still works.
- **Phone unreachable during workout:** keep displaying the last snapshot with `Reconnecting…`; allow one queued `setDone` per set and preserve it until acknowledgement. Never silently advance authoritative set state.
- **Rejected set:** retain the entered values and show the phone's short error plus Retry.
- **Duplicate acknowledgement:** no additional haptic and no second transition.
- **Image unavailable:** use `#141724` with a violet radial glow; never delay the exercise data.
- **No heart rate:** em dash immediately when no sample has arrived, or after the freshness threshold.
- **Workout ended on phone:** dismiss active controls, show summary acknowledgement, then return to idle.

## Open questions before implementation

1. What exact user setting determines pounds versus kilograms, and can load increments differ per exercise/equipment?
2. Should decreasing actual reps to zero mean a failed/skipped set, or must zero be disallowed?
3. Is exercise navigation allowed to reorder the phone's active pointer, or should swipes only preview adjacent exercises?
4. What are the exact cardio zone colors and zone-boundary source: percentage of max HR, HealthKit zones, or Strata configuration?
5. Are timer presets global, per exercise, or per user?
6. When connectivity drops, may the watch authoritatively log sets offline, or must all set completion wait for phone acknowledgement?
7. Should strength sessions contribute active calories/heart-rate display, and should the watch start the mirrored traditional-strength session automatically after the phone starts?
8. Is audio required for timer completion when the app is foregrounded, or is haptic-only acceptable in silent mode?
9. Should AOD display potentially sensitive load/plan information, or does the user need a privacy toggle?
10. Which Inter font files will be included in the Watch target, and is falling back to SF Compact acceptable if the custom font fails to load?

## Mockup boards

- `watch-strength-rest.png`: idle, current strength set, and rest in both sizes.
- `watch-timer.png`: picker, count-in, running, paused, and finished in both sizes.
- `watch-cardio-states.png`: cardio, 4×4, no-HR, disconnected, and always-on in both sizes.

The boards communicate visual direction. This document is authoritative when an image-generation artifact differs in typography, spacing, or text.
