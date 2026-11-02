# Screen parity checklist

For every screen: the elements in the web HTML, top to bottom, with copy, ticked off when built in
SwiftUI. `[x]` built, `[~]` built but its destination arrives in a later PR (the button is there,
and records the request in `AppModel.route`, but nothing opens yet), `[ ]` not built.

Layout notes that apply everywhere: the type, colour and radius tokens are `Strata/Theme.swift`
(from `style.css :root`); icons are the web's own SVG path data (`Strata/SVGPath.swift`), not SF
Symbols; photos are the web's `img/*.jpg`, bundled as a folder. The web uses Inter; iOS uses the
system font for now (the font files in `fonts.css` are WOFF2, which iOS can't load).

## First launch (`onboardView`) — `OnboardView.swift`
- [x] Hero (tall): logo + "Strata"; "Build it in layers:" / "muscle" (violet), "heart" (coral), "bone" (mint)
- [x] Sub: "4 lifts, 2–3 heart sessions and 2 jump warm-ups a week. Each one closes a ring."
- [x] Card "About you": Name field ("Your name"), Male / Female segmented, note "Sets your plan template and starting loads."
- [x] Card "Bring your history" (only after a gender is picked): "N sessions imported" (mint) or "Import a Lift Log export file" + note "Optional. In Lift Log: More → Export data, then pick that file here. Weights carry over, so nothing restarts."
  - Not on iOS: "Import N Lift Log sessions from this device" (it reads the browser's `localStorage`).
- [x] Card Age ("Age" / "For heart-rate targets", number field, placeholder "—", valid 14–99)
- [x] Card "Office days": note "Days you walk to work. Optional.", M T W T F chips
- [x] Dock button: "Get started", or disabled "Add your name and gender"

## Today (`todayView`) — `TodayView.swift`
- [x] Hero: eyebrow = weekday, month, day; title "Good morning|afternoon|evening, <name>"; sub "N-week streak. Keep the layers stacking." or "Build it in layers: muscle, heart, bone."
- [x] Main card for the selected day:
  - [x] Workout open: "In progress", plan name, "N of M main lifts logged"; [~] "Resume workout"
  - [x] Can't-train day: home session card (label "<when> · At home · <ring>", name, "~N min · no gym needed[ · <lift> moves to your next lift day]", the moves, "Mark done" / "Done · momentum kept", "Undo · I can train after all") or, when sick, "Recover first"
  - [x] Lift: missed ("Missed lift"), done ("<when> · Done", "N exercises · M min · jumps done", [~] "View session"), planned (label, plan name, "N main lifts · ~M min[ · jumps first]", photo thumbnails, rest-day warning, [~] "See workout" / "Preview")
  - [x] Office day: copy, steps field ("10,000") + "Log steps", "N steps logged" + "Edit"
  - [x] 4×4: done-this-week text, or copy with the hard target (or "Set your age in Settings for heart-rate targets."), [~] "Start 4×4" / "How the 4×4 works" / "Preview"
  - [x] Zone 2 walk / Long walk: copy with targets, "Done · N min on <day>", [~] "Start", "Already did it? Log the minutes:" + minutes field + "Log Zone 2" / "Log walk"
  - [x] Rest: "Recovery is where the adaptation happens."
  - [x] "Can't train today?" link (today, not rest, not done) → sheet
- [x] "Next lift in your rotation" card (name, "N main lifts · ~M min[ · jumps first]"), [~] "Open" / "Preview"
- [x] Today only, no workout open: [~] "Cardio first" / "Start cardio" and "Log a walk" (sheet)
- [x] "This week" rings card (Muscle / Heart / Bone, "N of 3 rings closed" / "All 3 rings closed", headline)
- [x] "This week · Tap a day" strip: weekday letter, state circle (check when done, dashed for home days), label (plan short name, Office, Z2, 4×4, Walk, Rest, Home)

## Sheets on Today
- [x] "Can't train today?": "Today", copy, the three reasons with their sub-lines
- [x] "Log a walk": Minutes (45), "Zone 2" / "Easy walk"
- [x] Cardio entry editor: date, name, steps / intervals / minutes field, "Delete" (confirm "Delete this entry?") / "Save"

## Toast
- [x] Pill at the top, 2.8 s, same copy as the web

## Workout preview (`previewView`) — `PreviewView.swift`
- [x] Hero (short) with back button: eyebrow date, plan name, "Glutes, legs and bone" / "Chest, back, shoulders, arms"
- [x] Pills: "~N min" (×0.75 rounded to 5 on a lighter day), "N main lifts", "N landings" (legs)
- [x] Rest-day warning (when a workout isn't open)
- [x] Warm-up card (legs or warm-up block): "Warm-up · Bone · 5 min" / "Do first"; Pogo hops 3 × 10, Box jumps 3 × 5 · step down, balance lifts "2 × r · balance"; form-video button on each
- [x] "Main lifts": photo, name, "sets × reps[ / leg] · **weight**[ · heavy][ · on hold]", "Last: w × reps · plates", form-video button
- [x] "Bonus · if time" (dashed) with "+N min" and the names (hidden on a lighter day)
- [x] "Feeling flat?" switch: "Lighter version: 85% weight, 2 sets, no bonus. Weights don't go up."
- [x] Dock: "Start with jumps" / "Start workout"; "Finish the open workout first" toast; rest-day confirm "…Start anyway?"

## Jumps warm-up (`jumpsView`) — `JumpsView.swift`
- [x] Hero (short): back (marks seen), eyebrow "Bone · <plan>", "Jumps warm-up", "Impact for bone density. Short, sharp, done before you lift."
- [x] Cards: photo, name, "sets × reps", form-video, how-to copy, Set buttons that toggle to a check
- [x] Dock: "Skip", "Mark done · start lifting" → "Done · start lifting" (mint) when all sets are done; logs 45 landings and the warm-up lifts

## Strength overview (`overviewView`) — `OverviewView.swift`
- [x] Top: plan name + live "mm:ss elapsed", "···" options sheet (Finish workout, Lighter day, Discard workout)
- [x] Eyebrow "Strength[ + Bone][ · lighter day]" (violet), plan name, progress bar, "N of M main lifts done"
- [x] Rest banner (Rest / Go, countdown, "+30 s", "Skip")
- [x] Legs: "Warm-up · Bone" → "Jumps warm-up" row ("Pogo hops 3 × 10 · Box jumps 3 × 5", check when done)
- [x] Groups "Basics / Compound / Isolation[ · if time]" with "d of n"; rows with photo, name, "n × reps · weight[ · swapped]" and Done check / "x/n" / "Busy" / "Next" / chevron
- [x] Dock: "Discard" (confirm) + "Complete" (finish prompts)

## Exercise in focus (`focusView`) — `FocusView.swift`
- [x] Photo header with back to the list, logo, exercise timer
- [x] Block tag ("Compound 1 of 2"), name, "n sets × reps", injury warning
- [x] "Last time" + trend chip (First time / Progressing / On track / Behind / Stalled / On hold)
- [x] Rest banner; "Today's weight" with −/+ and plate math
- [x] Warm-up rows (check, "Warm-up i", plates, Remove); set rows (Done + undo on the last, current with reps stepper + "Log", upcoming)
- [x] "+ Set", "+ Warm-up", "Form video", "Swap" (only when there are alternates), "Machine busy"
- [x] Dock: "Discard", "Complete" (confirms when sets are unlogged)
- [x] Sheets: warm-up options, "Machine busy?" swap list

## Countdown and lock
- [x] 3-2-1 overlay with "Strength · <plan>" / "Get ready" on first show; haptic cue at the end
- [x] The workout is a full-screen cover that can't be swiped away; screen stays awake; Complete / Discard are the only exits
- [ ] Starting the Apple Watch session after the countdown (phase 4)

## Workout complete (`doneView`) — `CompleteView.swift`
- [x] Hero (tall): "<plan> · <date>", "Workout complete", sub by outcome, check badge
- [x] Stats: Minutes, "main/required[ +bonus]" Lifts, "lb moved"
- [x] Rings card with "Still to go: …" / "All three layers done for the week."
- [x] "Next time": per lift, reps at weight, "N more reps unlocks W", up/Hold chip
- [x] "vs last <plan> · <date>" comparison with bars and legend; "Bone · impact" card; next-session card
- [x] Dock: [~] "Add cardio", "Done"

## Pick a cardio activity (`pickView`) — `PickCardioView.swift`
- [x] Back, logo; "Cardio" (coral), "Choose your workout"
- [x] Recommended card: "Recommended today:" + title (activity [· 4×4 / Zone 2]) + the sub-line from today's plan
- [x] "Recent": the last two distinct activities with "Today / Yesterday / <weekday> · N min"
- [x] "All": Outdoor bike, Indoor bike, Walk, Elliptical, Rower, Swim
- [x] Dock: "Start · <activity>[ · 4×4 / Zone 2]" → 3-2-1 → live session

## Cardio in progress (`cardioView`) — `CardioLiveView.swift`
- [x] "Cardio[ · mode]", activity name, "Workout in progress" pill
- [x] Heart rate: number + "bpm" + zone chip + zone name, "Target: stay in Z2 · a–b bpm"; no reading → "—" and the honest copy (`Config.Copy`); no age → "Add your age in Settings to see zones"
- [x] 4×4 phase card (label, countdown, hard / recover target, segmented phase bar); haptic at each phase change
- [x] "Time in zones" bar and Z1–Z5 times (only with age and readings)
- [x] Elapsed; Elevation (outdoor: "+N m" or "—" with Waiting for GPS / No GPS / Precise location off) or Avg heart rate (indoor)
- [x] Source chip: "Apple Watch: not yet supported" (changes with the watch in phase 4)
- [x] Dock: "Discard" (confirm) + "Complete"; the screen stays awake; a reopened app resumes the session
- Altitude is Core Location (readings less accurate than 20 m are dropped); heart rate has no source until the watch app.

## Cardio complete (`cDoneView`) and between blocks (`blockSheet`) — `CardioDoneView.swift`
- [x] Hero: "<activity>[ · 4×4 / Zone 2] · <date>", "Session complete", "Heart ring closed for the week." / "Heart work logged."
- [x] Minutes / Avg bpm / Hard intervals or m climbed or Max bpm; "Time in zones"
- [x] Footer chip: "Saved in Strata" (or "Saved to Apple Health" only when that really happened, phase 3)
- [x] Rings card; dock "Add block" + "Done"
- [x] Sheet: "<activity> · N min done"; "Add block: Strength · <plan>" (recommended, hidden if a lift was logged today); "End session"

## 4×4 screens (`vo2View`, `vo2DoneView`) — `Vo2Views.swift`
- [x] Info: treadmill hero, ramp-up line, the five steps, hard target (or "Set your age…"), 3 / 4 intervals switch, "Already did it? Log without the timer", "Start 4×4"
- [x] Logged: minutes, hard intervals, hard minutes, rings, ramp-up note, next-session card, "Done"
- Not ported: the standalone timer (`timerView`), unreachable on `main`.

## Not built yet (later PRs)
Tab bar, history and detail, progress, settings (the other three tabs).

## Not checked visually
Today and the screens above compile and share their data logic with the golden-tested core, but they have not yet
been looked at in a simulator (the simulator was unusable on the build machine). Compare on a device
or simulator before relying on spacing.
