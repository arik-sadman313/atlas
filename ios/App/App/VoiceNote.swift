import AVFoundation
import Speech
import SwiftUI

/// A voice note on the phone (vaultite://record: the Action button, a control, a widget): it records as it shows, its
/// words heard live (LiveWords.swift), then goes to the inbox like the watch's (WatchLink.swift's Voice).
@MainActor
final class VoiceNote: NSObject, ObservableObject {
    enum Step: Equatable { case starting, recording, sending, sent(String), failed(String) }
    @Published var step = Step.starting
    @Published var started = Date()
    /// How long it is, once stopped.
    @Published var length: TimeInterval?
    @Published var words = LiveWords()
    /// What hears it ("Soniox", "On this iPhone"), once known.
    @Published var hearer: String?
    /// A change on the way: the cloud dropped and this iPhone took over, or the words come once it's sent.
    @Published var line: String?
    /// Its words heard live are all of them (else they come after, from the recording).
    @Published var live = true
    @Published var levels: [Float] = []
    static let bars = 40

    private var recorder: VoiceRecorder?
    private var session: Session?
    private var heardAll = false
    private var ending: CheckedContinuation<Void, Never>?
    private var closed = false
    var close: () -> Void = {}

    func start() async {
        #if DEBUG
        let mic = VoiceRecorder.played == nil
        #else
        let mic = true
        #endif
        if mic {
            guard await AVAudioApplication.requestRecordPermission() else {
                return step = .failed("Vaultite may not use the microphone (Settings > Vaultite)")
            }
            // (for the older recognizer, should the words be transcribed after)
            if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
                _ = await withCheckedContinuation { c in SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) } }
            }
        }
        if closed { return } // (cancelled while it asked)
        do {
            Audio.shared.holdForRecording() // (what's playing waits for the note)
            if mic {
                try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            let r = try VoiceRecorder()
            r.ended = { [weak self] in Task { await self?.stop() } }
            let tell: Tell = { [weak self] h in DispatchQueue.main.async { MainActor.assumeIsolated { self?.heard(h) } } }
            let s = Session(source: r, silence: 0, tell: tell)
            // (recording at once: what's said while it asks the server waits for what hears it)
            s.start { [weak self] in
                let hearer = await Hearer.ask()
                await MainActor.run { self?.hearer = hearer.name; self?.words = hearer.words }
                return try await hearer.make(tell)
            }
            do { try r.record() } catch { s.stop("cancel"); throw error }
            recorder = r
            session = s
            started = Date()
            step = .recording
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            step = .failed(Servers.say(error))
            finish()
        }
    }

    private func heard(_ h: Heard) {
        switch h {
        case .pending(let text, let firm): words.show(text, firm: firm)
        case .final(let text): words.settle(text)
        case .level(let v): levels = Array((levels + [v]).suffix(Self.bars))
        case .fallback(let why):
            hearer = Hearer.here
            line = why
        case .error:
            live = false
            hearer = nil
            line = "Not hearing it live: its words come once it's sent"
        case .end:
            heardAll = true
            ending?.resume()
            ending = nil
        default: break
        }
    }

    /// Stop and send; a tap by mistake (under 0.7 s) isn't a note, and says so.
    func stop() async {
        guard step == .recording, let recorder, let session else { return }
        let long = recorder.finish()
        length = long
        finish()
        if long < 0.7 {
            session.stop("cancel")
            try? FileManager.default.removeItem(at: recorder.url)
            step = .failed("Too short, not saved")
            try? await Task.sleep(for: .seconds(1.5))
            return close()
        }
        step = .sending
        // (closed or locked meanwhile, it goes on; what iOS doesn't give it time for stays queued, sent next time)
        var task = UIBackgroundTaskIdentifier.invalid
        task = UIApplication.shared.beginBackgroundTask(withName: "voice") { UIApplication.shared.endBackgroundTask(task) }
        session.stop("stop")
        await lastWords(within: 6)
        let text = live && heardAll ? words.settled.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let outcome = await Voice.send(recorder.url, from: "iPhone", text: text.isEmpty ? nil : text)
        UIApplication.shared.endBackgroundTask(task)
        if let error = outcome["error"] as? String {
            step = .failed(error)
            if !closed { UINotificationFeedbackGenerator().notificationOccurred(.error) }
            return
        }
        if let said = outcome["text"] as? String, outcome["path"] as? String != nil {
            words.replace(said)
            step = .sent("In your inbox")
        } else {
            step = .sent(outcome["text"] as? String ?? "")
        }
        guard !closed else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        try? await Task.sleep(for: .seconds(1.5))
        close()
    }

    /// Its last words (the cloud's take a moment); much later, they come after from the recording instead.
    private func lastWords(within seconds: Double) async {
        guard !heardAll else { return }
        await withCheckedContinuation { c in
            ending = c
            Task {
                try? await Task.sleep(for: .seconds(seconds))
                ending?.resume()
                ending = nil
            }
        }
    }

    /// Thrown away while it records; once it's being sent, only the sheet goes.
    func cancel() {
        if step == .recording, let recorder {
            _ = recorder.finish()
            session?.stop("cancel")
            try? FileManager.default.removeItem(at: recorder.url)
            finish()
        }
        dismiss()
    }

    func dismiss() {
        closed = true
        close()
    }

    private func finish() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        Downloads.playback() // (back to playing, for the page's audio and video)
        Audio.shared.resumeAfterRecording()
    }
}

struct VoiceNoteView: View {
    @ObservedObject var note: VoiceNote

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if note.step == .recording || note.step == .starting {
                    Button("Cancel") { note.cancel() }
                } else {
                    Button("Close") { note.dismiss() }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            VStack(spacing: 10) {
                clock
                Levels(levels: note.levels, on: note.step == .recording)
                hearing
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
            Divider().opacity(0.5)
            Transcript(note: note)
            Divider().opacity(0.5)
            control.frame(height: 120)
        }
        .task { await note.start() }
    }

    @ViewBuilder private var clock: some View {
        if let length = note.length {
            Self.time(length)
        } else if note.step == .recording {
            TimelineView(.periodic(from: note.started, by: 1)) { t in Self.time(t.date.timeIntervalSince(note.started)) }
        } else {
            Self.time(0)
        }
    }

    private static func time(_ seconds: TimeInterval) -> some View {
        Text(Duration.seconds(seconds.rounded(.down)), format: .time(pattern: .minuteSecond))
            .font(.system(size: 56, weight: .light).monospacedDigit())
    }

    private var hearing: some View {
        VStack(spacing: 4) {
            Label(note.hearer ?? " ", systemImage: note.hearer == Hearer.here ? "iphone" : "cloud")
                .labelStyle(.titleAndIcon)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(note.hearer == nil ? 0 : 1)
            if let line = note.line {
                Text(line).font(.footnote).foregroundStyle(.orange).multilineTextAlignment(.center).lineLimit(2).padding(.horizontal, 24)
            }
        }
        .animation(.default, value: note.line)
    }

    @ViewBuilder private var control: some View {
        switch note.step {
        case .starting, .recording:
            Button { Task { await note.stop() } } label: {
                ZStack {
                    Circle().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 4)
                    RoundedRectangle(cornerRadius: 8).fill(.red).frame(width: 30, height: 30)
                }
                .frame(width: 76, height: 76)
            }
            .disabled(note.step == .starting)
            .accessibilityLabel("Stop and send")
        case .sending:
            HStack(spacing: 10) {
                ProgressView()
                Text("Sending to your inbox")
            }
            .foregroundStyle(.secondary)
        case .sent(let said):
            Label { Text(said).multilineTextAlignment(.center) } icon: { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                .padding(.horizontal, 24)
        case .failed(let why):
            Label { Text(why).multilineTextAlignment(.center) } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange) }
                .padding(.horizontal, 24)
        }
    }
}

/// The words as they're said: those that won't change in full, the few that may dimmed, kept scrolled to the newest.
private struct Transcript: View {
    @ObservedObject var note: VoiceNote

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                Group {
                    if note.words.all.isEmpty {
                        Text(note.live ? "Start talking" : "Its words come once it's sent").foregroundStyle(.tertiary)
                    } else {
                        Text(said)
                    }
                }
                .font(.title3)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                Color.clear.frame(height: 1).id("end")
            }
            .onChange(of: note.words.all) { withAnimation(.easeOut(duration: 0.2)) { scroll.scrollTo("end", anchor: .bottom) } }
        }
    }

    private var said: AttributedString {
        let all = note.words.all, loose = note.words.loose
        var text = AttributedString(String(all.dropLast(loose)))
        var pending = AttributedString(String(all.suffix(loose)))
        pending.foregroundColor = .secondary
        text.append(pending)
        return text
    }
}

/// The microphone's loudness the last few seconds, newest on the right.
private struct Levels: View {
    let levels: [Float]
    let on: Bool

    var body: some View {
        let shown = Array(repeating: Float(0), count: max(0, VoiceNote.bars - levels.count)) + levels
        HStack(spacing: 3) {
            ForEach(shown.indices, id: \.self) { i in
                Capsule()
                    .fill(on ? Color.red : Color.secondary.opacity(0.4))
                    .frame(width: 3, height: max(3, CGFloat(shown[i]) * 32))
            }
        }
        .frame(height: 32)
        .animation(.linear(duration: 0.1), value: levels)
        .accessibilityHidden(true)
    }
}
