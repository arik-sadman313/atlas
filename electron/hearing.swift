// What hears speech live, shared by the Mac's dictation helper (dictation.swift) and the iPhone's voice notes
// (ios/App/App/VoiceNote.swift): 16 kHz mono audio, a pause detector, and the engines it feeds.
import AVFoundation
import Foundation
import Speech

/// What hearing tells as it comes: the Mac's helper prints it (web/src/core/dictation.ts' DictationEvent), the phone
/// shows it. From any thread.
enum Heard {
    case start, speech
    case pause(ms: Int)
    case level(Float)
    /// The words heard since the last final ones, as they stand now ("" none); its first `firm` characters won't change
    /// (a cloud's final words, told as final at the next pause).
    case pending(String, firm: Int)
    case final(String)
    case loading(String)
    case fallback(String)
    case error(code: String, message: String)
    /// `settled`: ms from the stop to the last words.
    case end(reason: String, settled: Int?)
}
typealias Tell = (Heard) -> Void

struct Failure: Error { let code: String; let message: String }

// MARK: - Audio in: 16 kHz mono float, what both engines and the pause detector take

let RATE = 16000.0
let mono16k = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: RATE, channels: 1, interleaved: false)!

final class Resampler {
    let converter: AVAudioConverter
    let ratio: Double
    init?(from: AVAudioFormat, to: AVAudioFormat = mono16k) {
        guard let c = AVAudioConverter(from: from, to: to) else { return nil }
        converter = c
        ratio = to.sampleRate / from.sampleRate
    }
    func convert(_ b: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let cap = AVAudioFrameCount(Double(b.frameLength) * ratio + 64)
        guard let o = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: cap) else { return nil }
        var given = false
        var err: NSError?
        converter.convert(to: o, error: &err) { _, status in
            if given { status.pointee = .noDataNow; return nil }
            given = true
            status.pointee = .haveData
            return b
        }
        return err == nil ? o : nil
    }
    func samples(_ b: AVAudioPCMBuffer) -> [Float] {
        guard let o = convert(b), let p = o.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: p, count: Int(o.frameLength)))
    }
}

/// 16 kHz mono samples as a buffer.
func buffer16k(_ pcm: [Float]) -> AVAudioPCMBuffer? {
    guard !pcm.isEmpty, let b = AVAudioPCMBuffer(pcmFormat: mono16k, frameCapacity: AVAudioFrameCount(pcm.count)) else { return nil }
    b.frameLength = AVAudioFrameCount(pcm.count)
    pcm.withUnsafeBufferPointer { b.floatChannelData![0].update(from: $0.baseAddress!, count: pcm.count) }
    return b
}

protocol Source: AnyObject {
    func start(_ sink: @escaping ([Float]) -> Void) throws
    func stop()
}

/// A file played into the session as the microphone would (in real time unless `fast`), then a breath of silence.
final class FileSource: Source {
    let url: URL, fast: Bool, done: () -> Void
    var stopped = false
    init(_ url: URL, fast: Bool, done: @escaping () -> Void) { self.url = url; self.fast = fast; self.done = done }
    func start(_ sink: @escaping ([Float]) -> Void) throws {
        let file: AVAudioFile
        do { file = try AVAudioFile(forReading: url) } catch { throw Failure(code: "file", message: "Can't read \(url.path)") }
        guard let r = Resampler(from: file.processingFormat) else { throw Failure(code: "file", message: "Can't convert \(url.path)") }
        let chunk = AVAudioFrameCount(file.processingFormat.sampleRate / 10)
        Thread.detachNewThread { [self] in
            let t = Date()
            var fed = 0.0
            func pace() { if !fast { let wait = t.addingTimeInterval(fed).timeIntervalSinceNow; if wait > 0 { Thread.sleep(forTimeInterval: wait) } } }
            while !stopped, let b = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: chunk) {
                guard (try? file.read(into: b, frameCount: chunk)) != nil, b.frameLength > 0 else { break }
                sink(r.samples(b))
                fed += Double(b.frameLength) / file.processingFormat.sampleRate
                pace()
            }
            for _ in 0..<25 where !stopped { sink([Float](repeating: 0, count: 1600)); fed += 0.1; pace() }
            if !stopped { done() }
        }
    }
    func stop() { stopped = true }
}

// MARK: - Engines

protocol Engine: AnyObject {
    /// 16 kHz mono audio, in order: only while the user speaks and a moment around it (silence makes words up), unless it `hearsAll`.
    func feed(_ pcm: [Float])
    /// The user started speaking after a pause (the audio from a moment before comes next).
    func speech()
    /// The user paused (a clause's end): what was heard so far becomes final.
    func pause()
    /// The end: everything heard becomes final, then `done`.
    func finish(_ done: @escaping () -> Void)
    /// Dropped unfinished (cancelled): let go of what it holds.
    func cancel()
    /// Fed every sample, not only speech: one that noise doesn't make words up for (Soniox), so speech the pause
    /// detector misses (far from the mic, in a noisy room) still reaches it.
    var hearsAll: Bool { get }
}
extension Engine { func cancel() {}; var hearsAll: Bool { false } }

/// Apple's DictationTranscriber (macOS 26, iOS 26): volatile results are the pending words, final ones the text.
@available(macOS 26.0, iOS 26.0, *)
final class Apple: Engine {
    let transcriber: DictationTranscriber
    let analyzer: SpeechAnalyzer
    let input: AsyncStream<AnalyzerInput>.Continuation
    let format: AVAudioFormat
    let converter: Resampler?
    var results: Task<Void, Never>?

    static func locale(_ language: String) async -> Locale? {
        let wanted = language.isEmpty ? Locale.current : Locale(identifier: language)
        return await DictationTranscriber.supportedLocale(equivalentTo: wanted)
    }

    init(language: String, words: [String], tell: @escaping Tell) async throws {
        guard let loc = await Apple.locale(language) else {
            throw Failure(code: "language", message: "Apple's dictation has no \(language.isEmpty ? Locale.current.identifier : language)")
        }
        transcriber = DictationTranscriber(locale: loc, contentHints: [], transcriptionOptions: [.punctuation],
                                           reportingOptions: [.volatileResults, .frequentFinalization], attributeOptions: [])
        if let install = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            if !(await DictationTranscriber.installedLocales).contains(loc) { tell(.loading("language")) }
            try await install.downloadAndInstall()
        }
        format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) ?? mono16k
        converter = format == mono16k ? nil : Resampler(from: mono16k, to: format)
        let (stream, cont) = AsyncStream.makeStream(of: AnalyzerInput.self)
        input = cont
        analyzer = SpeechAnalyzer(modules: [transcriber])
        try await analyzer.prepareToAnalyze(in: format)
        // (words it should expect: names, "at Claude")
        if !words.isEmpty { let ctx = AnalysisContext(); ctx.contextualStrings[.general] = words; try? await analyzer.setContext(ctx) }
        try await analyzer.start(inputSequence: stream)
        let t = transcriber
        results = Task {
            do {
                for try await r in t.results {
                    let text = String(r.text.characters)
                    if r.isFinal {
                        if !text.isEmpty { tell(.final(text)) }
                        tell(.pending("", firm: 0))
                    } else {
                        tell(.pending(text, firm: 0))
                    }
                }
            } catch {
                tell(.error(code: "engine", message: error.localizedDescription))
            }
        }
    }

    func feed(_ pcm: [Float]) {
        guard let b = buffer16k(pcm), let x = converter.map({ $0.convert(b) }) ?? b else { return }
        input.yield(AnalyzerInput(buffer: x))
    }
    func speech() {}
    func pause() {
        let a = analyzer
        Task { try? await a.finalize(through: nil) }
    }
    func finish(_ done: @escaping () -> Void) {
        input.finish()
        let a = analyzer, r = results
        Task {
            try? await a.finalizeAndFinishThroughEndOfInput()
            await r?.value
            done()
        }
    }
}

/// A cloud recognizer in Soniox's real-time protocol at `url` (Soniox, or a server's relay): a pause or the stop asks
/// it to finalize. Failing, the device's engine (`local`) hears again what it hadn't settled.
final class SonioxStream: NSObject, Engine, URLSessionWebSocketDelegate, @unchecked Sendable {
    let q = DispatchQueue(label: "dictation.soniox")
    let local: () async throws -> Engine
    let tell: Tell
    let name: String, here: String
    let config: String
    var session: URLSession!
    var task: URLSessionWebSocketTask!
    var open = false, closed = false, dead = false
    var queued: [URLSessionWebSocketTask.Message] = []
    /// The audio sent from the last final word on (sample `keptAt` of the stream first): what a fallback hears again.
    var kept: [Float] = [], keptAt = 0, sent = 0, unasked = 0
    var finals = "", shown = "", paused = false
    /// Finalizes asked for, and their <fin>s back.
    var asked = 0, fins = 0
    var finishing: (() -> Void)?
    var fallback: Engine?, falling = false
    /// Gone to the device's engine: from then on it hears only speech, as that engine does (read on the session's queue).
    let fellLock = NSLock()
    var fellBack = false
    var hearsAll: Bool { fellLock.lock(); defer { fellLock.unlock() }; return !fellBack }
    var timer: DispatchSourceTimer?, lastSent = Date()
    /// The most a fallback hears again (the last final word on), in samples.
    static let KEPT = Int(RATE * 120)

    init(url: URL, key: String, model: String, languages: [String], words: [String], name: String, here: String,
         tell: @escaping Tell, local: @escaping () async throws -> Engine) {
        var start: [String: Any] = ["model": model, "audio_format": "pcm_s16le", "sample_rate": Int(RATE), "num_channels": 1]
        if !languages.isEmpty { start["language_hints"] = languages }
        if !words.isEmpty { start["context"] = ["terms": words] }
        config = (try? JSONSerialization.data(withJSONObject: start)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        self.local = local
        self.tell = tell
        self.name = name
        self.here = here
        super.init()
        var req = URLRequest(url: url, timeoutInterval: 5)
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let ops = OperationQueue()
        ops.underlyingQueue = q
        ops.maxConcurrentOperationCount = 1
        session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: ops)
        task = session.webSocketTask(with: req)
        q.async { [self] in
            task.resume()
            receive()
            // (no audio for a while, in a long quiet: Soniox drops a stream that says nothing)
            let t = DispatchSource.makeTimerSource(queue: q)
            t.schedule(deadline: .now() + 10, repeating: 10)
            t.setEventHandler { [weak self] in
                guard let self, self.open, !self.closed, Date().timeIntervalSince(self.lastSent) >= 10 else { return }
                self.send(.string("{\"type\":\"keepalive\"}"))
            }
            t.resume()
            timer = t
        }
    }

    func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol p: String?) {
        guard !closed else { return }
        open = true
        send(.string(config))
        for m in queued { send(m) }
        queued = []
    }
    // (the receive loop says it in turn, after what came before it: these only if it doesn't)
    func urlSession(_ s: URLSession, task t: URLSessionTask, didCompleteWithError error: Error?) { droppedSoon() }
    func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith code: URLSessionWebSocketTask.CloseCode, reason: Data?) { droppedSoon() }
    func droppedSoon() { q.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.dropped() } }
    /// The connection failed or went: why, as the handshake's answer tells.
    func dropped() {
        let status = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        fail(status == 401 || status == 403 ? "\(name) refused the key" : open ? "\(name)'s connection dropped" : status > 0 ? "\(name) answered \(status)" : "\(name) can't be reached")
    }

    func send(_ m: URLSessionWebSocketTask.Message) {
        guard !closed else { return }
        guard open else { queued.append(m); return }
        lastSent = Date()
        task.send(m) { [weak self] e in if e != nil { self?.droppedSoon() } }
    }
    func receive() {
        task.receive { [weak self] r in
            guard let self else { return }
            self.q.async {
                guard !self.closed else { return }
                switch r {
                case .success(.string(let text)): self.heard(text); self.receive()
                case .success: self.receive()
                case .failure: self.dropped()
                }
            }
        }
    }

    /// A response: final tokens wait for their <fin> (a pause's, the stop's) and settle whole, the rest show pending.
    func heard(_ text: String) {
        guard let d = text.data(using: .utf8), let m = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return }
        if let code = m["error_code"] {
            return fail("\(name): \(m["error_message"] as? String ?? "error \(code)")")
        }
        var tail = ""
        for t in m["tokens"] as? [[String: Any]] ?? [] {
            let s = t["text"] as? String ?? ""
            if s == "<fin>" || s == "<end>" {
                if s == "<fin>" { fins += 1 }
                settle()
            } else if t["is_final"] as? Bool == true {
                finals += s
                if let end = (t["end_ms"] as? NSNumber)?.intValue { forget(through: end * Int(RATE) / 1000) }
            } else {
                tail += s
            }
        }
        show((finals + tail).trimmingCharacters(in: .whitespaces), firm: finals.drop(while: \.isWhitespace).count)
        if let done = finishing, fins >= asked || m["finished"] as? Bool == true {
            settle()
            finishing = nil
            close()
            done()
        }
    }
    func show(_ text: String, firm: Int = 0) { if text != shown { shown = text; tell(.pending(text, firm: min(firm, text.count))) } }
    func settle() {
        let t = finals.trimmingCharacters(in: .whitespaces)
        finals = ""
        if !t.isEmpty { tell(.final(t)) }
        show("")
    }
    /// The audio up to sample `n` is in final words: a fallback needn't hear it.
    func forget(through n: Int) {
        let drop = min(n - keptAt, kept.count)
        if drop > 0 { kept.removeFirst(drop); keptAt += drop }
    }
    func askFinal() {
        guard unasked > 0 else { return }
        unasked = 0
        asked += 1
        send(.string("{\"type\":\"finalize\"}"))
    }

    func feed(_ pcm: [Float]) {
        q.async { [self] in
            if let f = fallback { return f.feed(pcm) }
            guard !dead else { return }
            kept.append(contentsOf: pcm)
            // (fed silence too now: a long quiet with no words to settle it is kept 2 min at most, trimmed in steps)
            if kept.count > SonioxStream.KEPT + Int(RATE * 10) { let drop = kept.count - SonioxStream.KEPT; kept.removeFirst(drop); keptAt += drop }
            if falling { return }
            sent += pcm.count
            unasked += pcm.count
            var d = Data(count: pcm.count * 2)
            d.withUnsafeMutableBytes { (b: UnsafeMutableRawBufferPointer) in
                let o = b.bindMemory(to: Int16.self)
                for (i, x) in pcm.enumerated() { o[i] = Int16(max(-1, min(1, x)) * 32767).littleEndian }
            }
            send(.data(d))
        }
    }
    func speech() { q.async { [self] in paused = false; fallback?.speech() } }
    func pause() {
        q.async { [self] in
            paused = true
            if let f = fallback { return f.pause() }
            if !falling { askFinal() }
        }
    }
    func finish(_ done: @escaping () -> Void) {
        q.async { [self] in
            if let f = fallback { return f.finish(done) }
            if dead { return done() }
            finishing = done
            if falling { return }
            askFinal()
            if fins >= asked { settle(); finishing = nil; close(); return done() }
            // (it answers a finalize in a few hundred ms; much later, the device finishes instead)
            q.asyncAfter(deadline: .now() + 4) { [weak self] in if let self, self.finishing != nil { self.fail("\(self.name) didn't answer in time") } }
        }
    }
    func cancel() { q.async { [self] in close(); fallback?.cancel() } }

    func close() {
        guard !closed else { return }
        closed = true
        timer?.cancel()
        task.cancel(with: .normalClosure, reason: nil)
        session.invalidateAndCancel()
    }

    /// The cloud is gone: what it settled stays, the device's engine hears the rest again and goes on.
    func fail(_ why: String) {
        guard !closed, fallback == nil, !falling else { return }
        fellLock.lock(); fellBack = true; fellLock.unlock()
        close()
        settle()
        falling = true
        tell(.fallback("\(why): dictating on \(here)"))
        Task {
            do {
                let e = try await local()
                q.async { [self] in
                    falling = false
                    fallback = e
                    e.speech()
                    e.feed(kept)
                    kept = []
                    if paused { e.pause() }
                    if let done = finishing { finishing = nil; e.finish(done) }
                }
            } catch {
                let f = error as? Failure
                q.async { [self] in
                    falling = false
                    dead = true
                    kept = []
                    tell(.error(code: "cloud", message: "\(why), and \(here)'s recognizer couldn't take over: \(f?.message ?? error.localizedDescription)"))
                    if let done = finishing { finishing = nil; done() }
                }
            }
        }
    }
}

// MARK: - A session: a source, its pause detector and an engine

final class Session: @unchecked Sendable {
    let work = DispatchQueue(label: "dictation.work")
    let source: Source
    let tell: Tell
    var silenceMs: Double
    var engine: Engine?
    var backlog: [[Float]] = []
    var ended = false
    var ending: String?
    // The pause detector: loudness against a floor that follows the room, in 20 ms frames.
    var floor: Float = 0.003
    var speaking = false, heard = false
    var quietMs = 0.0, sinceSpeechMs = 0.0
    var pausesSaid = Set<Int>()
    var open = false, preroll: [Float] = [], feeding: [Float] = []
    var level: Float = 0, levelMs = 0.0
    var onEnd: (() -> Void)?
    /// Every sample the source gives, as it comes, till the end (the Mac keeps or taps it).
    var onAudio: (([Float]) -> Void)?

    init(source: Source, silence: Double, tell: @escaping Tell) {
        self.source = source
        self.tell = tell
        silenceMs = silence * 1000
    }

    /// Listen at once, the audio kept until the engine is ready (`warm`: the engine first, as a test of its latency).
    func start(warm: Bool = false, make: @escaping () async throws -> Engine) {
        let listen = { [self] () -> Bool in
            do {
                try source.start { [weak self] pcm in self?.work.async { self?.audio(pcm) } }
            } catch let f as Failure {
                fail(f); return false
            } catch {
                fail(Failure(code: "mic", message: error.localizedDescription)); return false
            }
            tell(.start)
            return true
        }
        if !warm && !listen() { return }
        Task {
            do {
                let e = try await make()
                work.async { [self] in
                    guard !ended else { return e.finish {} }
                    engine = e
                    for pcm in backlog { process(pcm) }
                    backlog = []
                    if let reason = ending { ending = nil; end(reason) }
                    if warm { _ = listen() }
                }
            } catch let f as Failure {
                work.async { self.fail(f) }
            } catch {
                work.async { self.fail(Failure(code: "engine", message: error.localizedDescription)) }
            }
        }
    }

    func fail(_ f: Failure) {
        tell(.error(code: f.code, message: f.message))
        end("error", flush: false)
    }

    /// Audio arrives: its level now (for the indicator), the rest once the engine is ready.
    func audio(_ pcm: [Float]) {
        guard !ended, !pcm.isEmpty else { return }
        onAudio?(pcm)
        var sum: Float = 0
        for x in pcm { sum += x * x }
        level = max(level, (sum / Float(pcm.count)).squareRoot())
        levelMs += Double(pcm.count) / RATE * 1000
        if levelMs >= 100 {
            // (typed in steps: CI's older Swift gives up on the one expression)
            let db: Float = 20 * log10(max(level, 1e-6))
            let shown: Float = min(1, max(0, (db + 60) / 50))
            let v: Float = (shown * 100).rounded() / 100
            tell(.level(v))
            level = 0; levelMs = 0
        }
        if engine == nil { backlog.append(pcm) } else { process(pcm) }
    }

    func process(_ pcm: [Float]) {
        var i = 0
        let frame = Int(RATE * 0.02), all = engine?.hearsAll == true
        while i < pcm.count {
            let n = min(frame, pcm.count - i)
            let f = pcm[i..<(i + n)]
            i += n
            var sum: Float = 0
            for x in f { sum += x * x }
            let rms = (sum / Float(n)).squareRoot()
            let ms = Double(n) / RATE * 1000
            if rms < floor { floor = max(rms, 0.0005) } else { floor += (rms - floor) * 0.002 }
            if rms > max(floor * 3, 0.006) {
                quietMs = 0
                sinceSpeechMs = 0
                if !speaking {
                    speaking = true
                    heard = true
                    pausesSaid = []
                    tell(.speech)
                    engine?.speech()
                    if !open {
                        open = true
                        feeding.append(contentsOf: preroll)
                        preroll = []
                    }
                }
            } else {
                quietMs += ms
                sinceSpeechMs += ms
                // (a breath inside a word isn't a pause)
                if speaking && quietMs >= 250 { speaking = false }
            }
            if open || all { feeding.append(contentsOf: f) } else {
                preroll.append(contentsOf: f)
                if preroll.count > Session.PREROLL { preroll.removeFirst(preroll.count - Session.PREROLL) }
            }
            for p in [700, 2000] where heard && quietMs >= Double(p) && !pausesSaid.contains(p) {
                pausesSaid.insert(p)
                if p == 700 {
                    flush()
                    engine?.pause()
                }
                tell(.pause(ms: p))
            }
            if open && quietMs >= 1000 { flush(); open = false }
        }
        flush()
        if silenceMs > 0 && sinceSpeechMs >= silenceMs && !speaking { end("silence") }
    }
    static let PREROLL = Int(RATE * 0.4)
    func flush() {
        if !feeding.isEmpty { engine?.feed(feeding); feeding = [] }
    }

    /// Stop listening; what was heard becomes final (unless cancelled), then `end`.
    func end(_ reason: String, flush: Bool = true) {
        guard !ended else { return }
        // (stopped while the engine is still loading: what was said is heard first)
        if flush && engine == nil && !backlog.isEmpty { source.stop(); ending = reason; return }
        ended = true
        source.stop()
        let finish = { [self] in
            onAudio = nil
            tell(.end(reason: reason, settled: stopped.map { Int(Date().timeIntervalSince($0) * 1000) }))
            onEnd?()
        }
        if flush, let e = engine { e.finish { self.work.async(execute: finish) } } else { engine?.cancel(); finish() }
    }
    var stopped: Date?
    /// The microphone off at once (the engine may still be catching up), then the end in turn: the last words, `end`.
    func stop(_ reason: String) {
        if stopped == nil { stopped = Date() }
        source.stop()
        work.async { self.end(reason, flush: reason != "cancel") }
    }
}
