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

## Not built yet (later PRs)
Tab bar, workout preview, jumps warm-up, strength overview and focus, cardio picker / live / done,
between-blocks sheet, workout complete, history and detail, progress, settings. Exercise-level
screens use the same `Thumb`, `Hero`, `Card` and button styles added here.

## Not checked visually
These screens compile and share their data logic with the golden-tested core, but they have not yet
been looked at in a simulator (the simulator was unusable on the build machine). Compare on a device
or simulator before relying on spacing.
