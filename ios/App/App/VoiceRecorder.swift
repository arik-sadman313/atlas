import AVFoundation

/// A voice note's microphone. What it hears goes into the note's file as it comes (16 kHz mono AAC: the note itself,
/// whatever hears it live) and, as a Session's source (electron/hearing.swift), on to what hears it live.
final class VoiceRecorder: Source {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString).m4a")
    /// It stopped on its own (a call, the microphone gone, a played file's end): the note ends there, keeping what it has.
    var ended: () -> Void = {}

    private let q = DispatchQueue(label: "voice.recorder")
    private let mic = AVAudioEngine()
    private var file: AVAudioFile?
    private var frames = 0
    private var sink: (([Float]) -> Void)?
    private var observers: [NSObjectProtocol] = []
    private var listening = false
    #if DEBUG
    /// A file played in as the microphone (VAULTITE_VOICE_FILE: the simulator's test of the whole way).
    static let played = ProcessInfo.processInfo.environment["VAULTITE_VOICE_FILE"]
    private var player: FileSource?
    #endif

    init() throws {
        file = try AVAudioFile(forWriting: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: RATE, AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 24_000],
                               commonFormat: .pcmFormatFloat32, interleaved: false)
    }

    /// Recording from now on.
    func record() throws {
        #if DEBUG
        if let played = Self.played {
            let p = FileSource(URL(fileURLWithPath: played), fast: false) { [weak self] in DispatchQueue.main.async { self?.ended() } }
            try p.start { [weak self] pcm in self?.q.async { self?.heard(pcm) } }
            player = p
            return
        }
        #endif
        try tap()
        try mic.start()
        listening = true
        let nc = NotificationCenter.default
        observers = [
            nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
                guard let raw = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
                self?.ended()
            },
            nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in self?.ended() },
            // (another mic, AirPods put in: the engine stops, and goes on with the new one's format)
            nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: mic, queue: .main) { [weak self] _ in self?.again() },
        ]
    }

    /// The microphone off and the file closed: its seconds.
    func finish() -> TimeInterval {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        if listening {
            mic.inputNode.removeTap(onBus: 0)
            mic.stop()
            listening = false
        }
        #if DEBUG
        player?.stop()
        #endif
        return q.sync {
            file = nil
            return Double(frames) / RATE
        }
    }

    // The Session's: the file goes on being written past the end of what hears it (it failed: the words come after).
    func start(_ sink: @escaping ([Float]) -> Void) throws { q.sync { self.sink = sink } }
    func stop() { q.async { self.sink = nil } }

    private func tap() throws {
        let input = mic.inputNode, format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0, let r = Resampler(from: format) else {
            throw Servers.Failure("There's no microphone to listen to")
        }
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] b, _ in
            let pcm = r.samples(b)
            self?.q.async { self?.heard(pcm) }
        }
    }

    private func again() {
        guard listening else { return }
        mic.inputNode.removeTap(onBus: 0)
        do { try tap(); try mic.start() } catch { ended() }
    }

    private func heard(_ pcm: [Float]) {
        guard let file, let b = buffer16k(pcm), (try? file.write(from: b)) != nil else { return }
        frames += pcm.count
        sink?(pcm)
    }
}
