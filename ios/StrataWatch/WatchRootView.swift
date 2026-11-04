import StrataCore
import SwiftUI
import WatchKit

private enum WatchTheme {
    static let background = Color(red: 14 / 255, green: 16 / 255, blue: 24 / 255)
    static let surface = Color.white.opacity(0.08)
    static let line = Color.white.opacity(0.12)
    static let text = Color(red: 244 / 255, green: 245 / 255, blue: 248 / 255)
    static let muted = Color(red: 169 / 255, green: 174 / 255, blue: 189 / 255)
    static let dim = Color(red: 110 / 255, green: 115 / 255, blue: 133 / 255)
    static let violet = Color(red: 156 / 255, green: 140 / 255, blue: 255 / 255)
    static let coral = Color(red: 255 / 255, green: 107 / 255, blue: 74 / 255)
}

struct WatchRootView: View {
    @EnvironmentObject private var workout: WatchWorkout
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @State private var timerPresented = false

    var body: some View {
        Group {
            if let rest = workout.state.rest {
                WatchRestView(rest: rest, isLuminanceReduced: isLuminanceReduced,
                              openTimer: { timerPresented = true }, skip: workout.skipRest)
            } else {
                switch workout.state.mode {
                case .strength:
                    if let exercise = workout.state.exercise {
                        WatchStrengthView(
                            exercise: exercise,
                            pending: workout.pendingCommandID != nil,
                            error: workout.commandError,
                            isLuminanceReduced: isLuminanceReduced,
                            openTimer: { timerPresented = true },
                            done: workout.completeSet,
                            navigate: workout.navigateExercise
                        )
                    } else {
                        WatchEmptyView(openTimer: { timerPresented = true })
                    }
                case .cardio:
                    WatchCardioView(
                        cardio: workout.state.cardio,
                        heartRate: workout.hr,
                        started: workout.started,
                        isLuminanceReduced: isLuminanceReduced,
                        openTimer: { timerPresented = true }
                    )
                case .idle:
                    WatchIdleView(plan: workout.state.plan, pending: workout.pendingCommandID != nil,
                                  openTimer: { timerPresented = true }, start: workout.startPlan)
                }
            }
        }
        .foregroundStyle(WatchTheme.text)
        .containerBackground(WatchTheme.background.gradient, for: .navigation)
        .sheet(isPresented: $timerPresented) {
            WatchTimerView(exercise: workout.state.exercise) { seconds in
                guard let exercise = workout.state.exercise else { return }
                workout.completeSet(reps: Double(seconds), load: exercise.load)
            }
        }
        .task { workout.requestState() }
    }
}

private struct WatchIdleView: View {
    let plan: WatchPlanSnapshot?
    let pending: Bool
    let openTimer: () -> Void
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if plan != nil {
                    Circle().fill(WatchTheme.violet).frame(width: 7, height: 7)
                    Text("TODAY").font(.system(size: 10, weight: .bold)).tracking(1)
                        .foregroundStyle(WatchTheme.violet)
                }
                Spacer()
                TimerButton(action: openTimer)
            }
            Spacer(minLength: 0)
            if let plan {
                Text(plan.name)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.75)
                Text(plan.detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WatchTheme.muted)
                Button(action: start) {
                    Group {
                        if pending { ProgressView().tint(WatchTheme.background) }
                        else { Text("Start") }
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: WatchTheme.violet))
                .disabled(pending)
            } else {
                Spacer(minLength: 0)
                Image(systemName: "mountain.2")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(WatchTheme.violet.opacity(0.7))
                    .frame(maxWidth: .infinity)
                Text("No plan yet")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                Text("Open Strata on your iPhone")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WatchTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct WatchEmptyView: View {
    let openTimer: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack { Spacer(); TimerButton(action: openTimer) }
            Spacer()
            Text("Open Strata on your iPhone")
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("Waiting for workout details")
                .font(.system(size: 11))
                .foregroundStyle(WatchTheme.muted)
            Spacer()
        }
    }
}

private struct WatchStrengthView: View {
    let exercise: WatchExerciseSnapshot
    let pending: Bool
    let error: String?
    let isLuminanceReduced: Bool
    let openTimer: () -> Void
    let done: (Double, Double) -> Void
    let navigate: (Int) -> Void

    @State private var actualReps = 0.0
    @State private var actualLoad = 0.0
    @State private var crownValue = 0.0
    @State private var editingLoad = false

    var body: some View {
        ZStack {
            if !isLuminanceReduced, let imageName = exercise.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
            }
            LinearGradient(
                colors: [WatchTheme.background.opacity(isLuminanceReduced ? 1 : 0.68),
                         WatchTheme.background.opacity(isLuminanceReduced ? 1 : 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(exercise.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .lineLimit(2)
                        Text("SET \(exercise.setIndex) OF \(exercise.setCount)")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(isLuminanceReduced ? WatchTheme.dim : WatchTheme.muted)
                    }
                    Spacer(minLength: 2)
                    if !isLuminanceReduced { TimerButton(action: openTimer) }
                }
                Spacer(minLength: 1)
                HStack(spacing: 7) {
                    if !isLuminanceReduced {
                        StepButton(symbol: "minus") { changeReps(-1) }
                    }
                    Text("\(watchNumber(actualReps)) reps")
                        .font(.system(size: isLuminanceReduced ? 38 : 40, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    if !isLuminanceReduced {
                        StepButton(symbol: "plus") { changeReps(1) }
                    }
                }
                Button {
                    editingLoad = true
                    crownValue = actualLoad
                } label: {
                    Text("\(watchNumber(actualLoad)) \(exercise.loadUnit)")
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(editingLoad && !isLuminanceReduced ? WatchTheme.violet : WatchTheme.text)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(isLuminanceReduced)
                if !isLuminanceReduced {
                    if let last = exercise.lastSummary {
                        Text(last).font(.system(size: 10, weight: .medium)).foregroundStyle(WatchTheme.muted)
                            .lineLimit(1).minimumScaleFactor(0.75).frame(maxWidth: .infinity)
                    }
                    if let error {
                        Text(error).font(.system(size: 10, weight: .semibold)).foregroundStyle(WatchTheme.coral)
                            .lineLimit(1).frame(maxWidth: .infinity)
                    }
                    Button {
                        done(actualReps, actualLoad)
                    } label: {
                        if pending { ProgressView().tint(WatchTheme.background) }
                        else { Text("Done") }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: WatchTheme.violet))
                    .disabled(pending)
                } else {
                    Capsule().fill(WatchTheme.violet.opacity(0.5)).frame(height: 4).padding(.top, 3)
                }
            }
            .padding(.horizontal, 3)
        }
        .clipped()
        .focusable(!isLuminanceReduced)
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: editingLoad ? 2000 : 1000,
            by: editingLoad ? max(0.5, exercise.loadIncrement) : 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, newValue in
            if editingLoad { actualLoad = newValue } else { actualReps = newValue }
        }
        .onChange(of: exercise.id, initial: true) {
            actualReps = exercise.targetReps
            actualLoad = exercise.load
            editingLoad = false
            crownValue = exercise.targetReps
        }
        .gesture(
            DragGesture(minimumDistance: 35).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                navigate(value.translation.width < 0 ? 1 : -1)
            }
        )
        .accessibilityElement(children: .contain)
    }

    private func changeReps(_ direction: Double) {
        editingLoad = false
        actualReps = max(0, actualReps + direction)
        crownValue = actualReps
    }
}

private struct WatchRestView: View {
    let rest: WatchRestSnapshot
    let isLuminanceReduced: Bool
    let openTimer: () -> Void
    let skip: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(ceil(rest.endsAt.timeIntervalSince(context.date))))
            VStack(spacing: 6) {
                HStack {
                    Text("REST").font(.system(size: 10, weight: .bold)).tracking(1.2)
                        .foregroundStyle(isLuminanceReduced ? WatchTheme.dim : WatchTheme.violet)
                    Spacer()
                    if !isLuminanceReduced { TimerButton(action: openTimer) }
                }
                ZStack {
                    Circle().stroke(WatchTheme.surface, lineWidth: 6)
                    Circle().trim(from: 0, to: min(1, Double(remaining) / 180))
                        .stroke(WatchTheme.violet.opacity(isLuminanceReduced ? 0.45 : 1),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(watchClock(remaining))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .frame(height: 92)
                if !isLuminanceReduced {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("NEXT").font(.system(size: 9, weight: .bold)).tracking(1)
                            .foregroundStyle(WatchTheme.muted)
                        Text(rest.nextName ?? "Next set").font(.system(size: 14, weight: .bold)).lineLimit(1)
                        if let target = rest.nextTarget {
                            Text(target).font(.system(size: 11, weight: .medium)).foregroundStyle(WatchTheme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8).background(WatchTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    Button("Skip", action: skip).buttonStyle(GlassButtonStyle())
                }
            }
        }
    }
}

private struct WatchCardioView: View {
    let cardio: WatchCardioSnapshot?
    let heartRate: Double?
    let started: Date?
    let isLuminanceReduced: Bool
    let openTimer: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 5) {
                HStack {
                    Text(cardio?.phaseName?.uppercased() ?? "RUNNING")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2)
                        .foregroundStyle(isLuminanceReduced ? WatchTheme.dim : WatchTheme.coral)
                    Spacer()
                    if !isLuminanceReduced { TimerButton(action: openTimer) }
                }
                Spacer(minLength: 0)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(heartRate.map { String(Int($0.rounded())) } ?? "—")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isLuminanceReduced ? WatchTheme.text.opacity(0.6) : WatchTheme.coral)
                    Text("bpm").font(.system(size: 16, weight: .medium)).foregroundStyle(WatchTheme.muted)
                }
                if let phaseEndsAt = cardio?.phaseEndsAt {
                    Text("\(watchClock(Int(ceil(phaseEndsAt.timeIntervalSince(context.date))))) left")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                } else if let zone = cardio?.zoneName {
                    Text(zone.uppercased()).font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(WatchTheme.coral.opacity(0.28), in: Capsule())
                } else if heartRate == nil {
                    Text("HEART RATE UNAVAILABLE").font(.system(size: 9, weight: .bold))
                        .foregroundStyle(WatchTheme.muted)
                }
                let origin = cardio?.startedAt ?? started
                Text(watchClock(Int(context.date.timeIntervalSince(origin ?? context.date))))
                    .font(.system(size: 29, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Spacer(minLength: 0)
            }
        }
    }
}

private struct TimerButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "stopwatch")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 34, height: 34)
                .background(WatchTheme.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open timer")
    }
}

private struct StepButton: View {
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold))
                .frame(width: 34, height: 34).background(WatchTheme.surface, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(WatchTheme.background)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(WatchTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(WatchTheme.line))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private enum TimerPhase { case picker, countIn, running, paused, finished }

private struct WatchTimerView: View {
    let exercise: WatchExerciseSnapshot?
    let logTimedSet: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSeconds: Double
    @State private var phase = TimerPhase.picker
    @State private var countIn = 3
    @State private var endAt: Date?
    @State private var pausedSeconds = 0
    @State private var timerTask: Task<Void, Never>?

    init(exercise: WatchExerciseSnapshot?, logTimedSet: @escaping (Int) -> Void) {
        self.exercise = exercise
        self.logTimedSet = logTimedSet
        _selectedSeconds = State(initialValue: Double(exercise?.durationSeconds ?? 90))
    }

    var body: some View {
        Group {
            switch phase {
            case .picker: picker
            case .countIn: countInView
            case .running, .paused: runningView
            case .finished: finishedView
            }
        }
        .foregroundStyle(WatchTheme.text)
        .containerBackground(WatchTheme.background.gradient, for: .navigation)
        .onDisappear { timerTask?.cancel() }
    }

    private var picker: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Timer").font(.system(size: 17, weight: .bold))
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            Text(watchClock(Int(selectedSeconds)))
                .font(.system(size: 43, weight: .heavy, design: .rounded)).monospacedDigit()
                .focusable()
                .digitalCrownRotation($selectedSeconds, from: 5, through: 5_940, by: 5,
                                      sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
            HStack(spacing: 5) {
                preset(30); preset(60); preset(90)
            }
            Button("Start", action: startCountIn).buttonStyle(PrimaryButtonStyle(color: WatchTheme.violet))
        }
    }

    private var countInView: some View {
        VStack(spacing: 4) {
            Text("\(countIn)")
                .font(.system(size: 84, weight: .heavy, design: .rounded))
                .foregroundStyle(WatchTheme.violet)
            Text("GET READY").font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundStyle(WatchTheme.muted)
        }
    }

    private var runningView: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let remaining = phase == .paused ? pausedSeconds : max(0, Int(ceil(endAt?.timeIntervalSince(context.date) ?? 0)))
            VStack(spacing: 7) {
                Text(phase == .paused ? "PAUSED" : (exercise?.name.uppercased() ?? "TIMER"))
                    .font(.system(size: 10, weight: .bold)).tracking(1)
                    .foregroundStyle(WatchTheme.muted).lineLimit(1)
                ZStack {
                    Circle().stroke(WatchTheme.surface, lineWidth: 6)
                    Circle().trim(from: 0, to: selectedSeconds == 0 ? 0 : Double(remaining) / selectedSeconds)
                        .stroke(WatchTheme.violet, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(watchClock(remaining))
                        .font(.system(size: 37, weight: .heavy, design: .rounded)).monospacedDigit()
                }
                .frame(height: 116)
                if phase == .paused {
                    HStack {
                        Button("Resume", action: resume).buttonStyle(PrimaryButtonStyle(color: WatchTheme.violet))
                        Button("Cancel") { phase = .picker }.buttonStyle(GlassButtonStyle())
                    }
                } else {
                    Button("Pause", action: pause).buttonStyle(GlassButtonStyle())
                }
            }
        }
    }

    private var finishedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark").font(.system(size: 27, weight: .bold))
                .frame(width: 52, height: 52).background(WatchTheme.violet, in: Circle())
                .foregroundStyle(WatchTheme.background)
            Text("Done").font(.system(size: 27, weight: .heavy, design: .rounded))
            Text("\(watchClock(Int(selectedSeconds))) complete")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(WatchTheme.muted)
            Button(exercise == nil ? "Done" : "Log set") {
                if exercise != nil { logTimedSet(Int(selectedSeconds)) }
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(color: WatchTheme.violet))
        }
    }

    private func preset(_ seconds: Int) -> some View {
        Button(watchClock(seconds)) { selectedSeconds = Double(seconds) }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.bordered)
            .tint(Int(selectedSeconds) == seconds ? WatchTheme.violet : WatchTheme.surface)
    }

    private func startCountIn() {
        phase = .countIn
        timerTask?.cancel()
        timerTask = Task {
            for value in stride(from: 3, through: 1, by: -1) {
                countIn = value
                WKInterfaceDevice.current().play(.click)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
            }
            startRunning(seconds: Int(selectedSeconds))
        }
    }

    private func startRunning(seconds: Int) {
        endAt = Date().addingTimeInterval(Double(seconds))
        phase = .running
        scheduleFinish(after: seconds)
    }

    private func pause() {
        pausedSeconds = max(0, Int(ceil(endAt?.timeIntervalSinceNow ?? 0)))
        timerTask?.cancel()
        phase = .paused
    }

    private func resume() {
        startRunning(seconds: pausedSeconds)
    }

    private func scheduleFinish(after seconds: Int) {
        timerTask?.cancel()
        timerTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(max(0, seconds)) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            phase = .finished
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

private func watchNumber(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
}

private func watchClock(_ seconds: Int) -> String {
    String(format: "%02d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
}
