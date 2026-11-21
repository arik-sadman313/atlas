// Live dictation (electron/dictation.ts): the microphone through Apple's recognizer, Parakeet (transcribe.cpp)
// or Soniox's cloud one when a start brings its key (hearing.swift), told as JSON lines.
import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation
import Speech
#if PARAKEET
import CTranscribe
#endif

// MARK: - Output

let outLock = NSLock()
var started = Date()
/// The session the events are of (the app's number for it): one ends before the next starts, so none mixes.
var sessionId = 0
/// What's of no session: the engines here, the devices, the mic held past its session.
let unsessioned: Set<String> = ["engines", "devices", "mic-held", "mic-released"]
func emit(_ type: String, _ fields: [String: Any] = [:]) {
    var o = fields
    o["type"] = type
    if sessionId > 0 && !unsessioned.contains(type) { o["id"] = sessionId }
    o["at"] = Int(Date().timeIntervalSince(started) * 1000)
    guard let d = try? JSONSerialization.data(withJSONObject: o) else { return }
    outLock.lock()
    FileHandle.standardOutput.write(d + Data([10]))
    outLock.unlock()
}
/// What hearing tells, as web/src/core/dictation.ts' DictationEvent.
func emit(_ h: Heard) {
    switch h {
    case .start: emit("start")
    case .speech: emit("speech")
    case .pause(let ms): emit("pause", ["ms": ms])
    case .level(let v): emit("level", ["v": v])
    case .pending(let text, _): emit("pending", ["text": text])
    case .final(let text): emit("final", ["text": text])
    case .loading(let what): emit("loading", ["what": what])
    case .fallback(let message): emit("fallback", ["message": message])
    case .error(let code, let message): emit("error", ["code": code, "message": message])
    case .end(let reason, let settled):
        var o: [String: Any] = ["reason": reason]
        if let settled { o["settled"] = settled }
        emit("end", o)
    }
}

// MARK: - Devices: listed for the app to pick from (electron/miclogic.ts), told again whenever they change

struct AudioDev { let id: AudioDeviceID; let uid: String; let name: String; let transport: String; let input: Bool; let output: Bool
    var bluetooth: Bool { transport == "blue" || transport == "blea" }
    var json: [String: Any] { ["uid": uid, "name": name, "transport": transport, "input": input, "output": output] }
}

func address(_ s: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: s, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}
func readU32(_ obj: AudioObjectID, _ s: AudioObjectPropertySelector) -> UInt32? {
    var a = address(s), v: UInt32 = 0, size = UInt32(MemoryLayout<UInt32>.size)
    return AudioObjectGetPropertyData(obj, &a, 0, nil, &size, &v) == noErr ? v : nil
}
func readString(_ obj: AudioObjectID, _ s: AudioObjectPropertySelector) -> String? {
    var a = address(s), v: Unmanaged<CFString>?, size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(obj, &a, 0, nil, &size, &v) == noErr, let str = v?.takeRetainedValue() else { return nil }
    return str as String
}
func hasStreams(_ id: AudioDeviceID, _ scope: AudioObjectPropertyScope) -> Bool {
    var a = address(kAudioDevicePropertyStreams, scope), size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(id, &a, 0, nil, &size) == noErr && size > 0
}
/// Core Audio's four-letter code as text ("bltn", "blue", "usb"); 0 is "unknown".
func fourcc(_ v: UInt32) -> String {
    if v == 0 { return "unknown" }
    let bytes = [24, 16, 8, 0].map { UInt8((v >> UInt32($0)) & 0xff) }
    return (String(bytes: bytes, encoding: .ascii) ?? "\(v)").trimmingCharacters(in: .whitespaces)
}
func audioDevices() -> [AudioDev] {
    var a = address(kAudioHardwarePropertyDevices), size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size) == noErr, size > 0 else { return [] }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &ids) == noErr else { return [] }
    return ids.compactMap { id in
        guard let uid = readString(id, kAudioDevicePropertyDeviceUID) else { return nil }
        return AudioDev(id: id, uid: uid, name: readString(id, kAudioObjectPropertyName) ?? uid, transport: fourcc(readU32(id, kAudioDevicePropertyTransportType) ?? 0),
                        input: hasStreams(id, kAudioDevicePropertyScopeInput), output: hasStreams(id, kAudioDevicePropertyScopeOutput))
    }
}
func defaultDevice(_ s: AudioObjectPropertySelector) -> AudioDeviceID? { readU32(AudioObjectID(kAudioObjectSystemObject), s) }

func tellDevices() {
    let all = audioDevices(), inId = defaultDevice(kAudioHardwarePropertyDefaultInputDevice), outId = defaultDevice(kAudioHardwarePropertyDefaultOutputDevice)
    emit("devices", ["devices": all.map(\.json), "input": all.first { $0.id == inId }?.uid ?? "", "output": all.first { $0.id == outId }?.uid ?? ""])
}
var devicesSoon = false
/// Devices plugged, unplugged, the defaults changed: told once things settle, and the mic open checks its own is still here.
func watchDevices() {
    for s in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice, kAudioHardwarePropertyDefaultOutputDevice] {
        var a = address(s)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &a, DispatchQueue.main) { _, _ in
            guard !devicesSoon else { return }
            devicesSoon = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                devicesSoon = false
                tellDevices()
                for m in Microphone.open { m.check() }
            }
        }
    }
}

/// The mic: the first of `want` (uids) here, else the system's input, opened again on the next should it go mid-capture.
/// `hold`: a Bluetooth one stays open past its session till `release`, so the headset keeps its profile mid-answer.
/// It's Core Audio's input unit alone, not an AVAudioEngine: an engine opens the system's output too, so a headset
/// switching its profile (AirPods while another mic is picked) stopped it, and opening it again switched it back.
final class Microphone: Source {
    static var open: [Microphone] = []
    let want: [String]
    var hold = false
    var sink: (([Float]) -> Void)?
    var device: AudioDev?
    var running = false, holding = false, reopening = false
    var failed: ((Failure) -> Void)?
    var releaseAt: DispatchWorkItem?
    var unit: AudioUnit?
    var format: AVAudioFormat?
    var resampler: Resampler?
    var following = false
    var reopens: [Date] = []
    var rateListener: (AudioDeviceID, AudioObjectPropertyListenerBlock)?
    let queue = DispatchQueue(label: "dictation.mic")
    init(want: [String]) { self.want = want }

    func start(_ sink: @escaping ([Float]) -> Void) throws {
        self.sink = sink
        // (a held one taken on: hearing already)
        if running {
            holding = false
            releaseAt?.cancel()
            if let d = device { emit("mic", d.json.merging(["bluetooth": d.bluetooth, "held": true]) { a, _ in a }) }
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied, .restricted: throw Failure(code: "permission", message: "Vaultite isn't allowed to use the microphone")
        default: break
        }
        try begin(why: nil)
    }

    func begin(why: String?) throws {
        let inputs = audioDevices().filter(\.input)
        let inId = defaultDevice(kAudioHardwarePropertyDefaultInputDevice)
        let wanted = want.compactMap { u in inputs.first { $0.uid == u } }
        // (those asked for in order, then the system's input; one that won't open, the next)
        let order = wanted + inputs.filter { d in d.id == inId && !wanted.contains { $0.id == d.id } }
        guard !order.isEmpty else { throw Failure(code: "mic", message: "There's no microphone to listen to") }
        var refused: [String] = []
        var failure: Error?
        for pick in order {
            do { try open(pick) } catch { teardown(); failure = error; refused.append(pick.name); continue }
            following = !wanted.contains { $0.id == pick.id }
            running = true
            if !Microphone.open.contains(where: { $0 === self }) { Microphone.open.append(self) }
            device = pick
            var o: [String: Any] = pick.json.merging(["bluetooth": pick.bluetooth]) { a, _ in a }
            if let w = why ?? refused.last.map({ "\($0) wouldn't open" }) { o["why"] = w }
            if let first = want.first, !first.isEmpty, pick.uid != first { o["missing"] = first }
            emit("mic", o)
            return
        }
        throw failure ?? Failure(code: "mic", message: "There's no microphone to listen to")
    }

    /// The input unit on `d`, its samples as floats at the device's rate, each buffer to the sink off the audio thread.
    func open(_ d: AudioDev) throws {
        let fail = { (what: String, err: OSStatus) in Failure(code: "mic", message: "The microphone didn't start: \(what) (\(err))") }
        var desc = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_HALOutput,
                                             componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        guard let comp = AudioComponentFindNext(nil, &desc) else { throw Failure(code: "mic", message: "There's no microphone to listen to") }
        var u: AudioUnit?
        var err = AudioComponentInstanceNew(comp, &u)
        guard err == noErr, let u else { throw fail("no input unit", err) }
        unit = u
        let u32 = UInt32(MemoryLayout<UInt32>.size)
        var on: UInt32 = 1, off: UInt32 = 0
        err = AudioUnitSetProperty(u, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &on, u32)
        guard err == noErr else { throw fail("input refused", err) }
        err = AudioUnitSetProperty(u, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &off, u32)
        guard err == noErr else { throw fail("output refused", err) }
        var id = d.id
        err = AudioUnitSetProperty(u, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &id, UInt32(MemoryLayout<AudioDeviceID>.size))
        guard err == noErr else { throw fail("couldn't pick \(d.name)", err) }
        var hw = AudioStreamBasicDescription(), size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        err = AudioUnitGetProperty(u, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &hw, &size)
        guard err == noErr, hw.mSampleRate > 0, hw.mChannelsPerFrame > 0,
              let f = AVAudioFormat(standardFormatWithSampleRate: hw.mSampleRate, channels: hw.mChannelsPerFrame), let r = Resampler(from: f) else {
            throw Failure(code: "mic", message: "There's no microphone to listen to")
        }
        var client = f.streamDescription.pointee
        err = AudioUnitSetProperty(u, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &client, size)
        guard err == noErr else { throw fail("format refused", err) }
        format = f
        resampler = r
        var cb = AURenderCallbackStruct(inputProc: { ref, flags, time, bus, frames, _ in
            Unmanaged<Microphone>.fromOpaque(ref).takeUnretainedValue().render(flags, time, bus, frames)
        }, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
        err = AudioUnitSetProperty(u, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, &cb, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        guard err == noErr else { throw fail("no callback", err) }
        err = AudioUnitInitialize(u)
        guard err == noErr else { throw fail("couldn't open \(d.name)", err) }
        // (its rate changing under it, a headset going to a call's: opened again on the new one)
        var a = address(kAudioDevicePropertyNominalSampleRate)
        let l: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.changed("rate") }
        if AudioObjectAddPropertyListenerBlock(d.id, &a, DispatchQueue.main, l) == noErr { rateListener = (d.id, l) }
        err = AudioOutputUnitStart(u)
        guard err == noErr else { throw fail("couldn't start \(d.name)", err) }
    }

    /// The audio thread: the unit's frames rendered into a buffer, converted and handed on in order on the mic's queue.
    func render(_ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, _ time: UnsafePointer<AudioTimeStamp>, _ bus: UInt32, _ frames: UInt32) -> OSStatus {
        guard let u = unit, let f = format, let b = AVAudioPCMBuffer(pcmFormat: f, frameCapacity: frames) else { return noErr }
        b.frameLength = frames
        let err = AudioUnitRender(u, flags, time, bus, frames, b.mutableAudioBufferList)
        guard err == noErr, sink != nil, let r = resampler else { return err }
        queue.async { [weak self] in
            guard let sink = self?.sink else { return }
            sink(r.samples(b))
        }
        return noErr
    }

    /// The device list or the defaults changed: its own device gone, or the system's input changed while it follows
    /// it, it opens again on the next.
    func check() {
        guard running, let d = device else { return }
        if !audioDevices().contains(where: { $0.uid == d.uid && $0.input }) { return changed("gone: \(d.name)") }
        if following, let now = defaultDevice(kAudioHardwarePropertyDefaultInputDevice), now != d.id { changed("the system's input changed") }
    }
    /// Its device went or changed under it: open again a moment on, on the first still here (a few times at most:
    /// one that keeps changing fails, never loops).
    func changed(_ why: String) {
        guard running, !reopening else { return }
        if holding { return close() }
        reopening = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            reopening = false
            guard running, !holding else { return }
            reopens = reopens.filter { $0.timeIntervalSinceNow > -10 } + [Date()]
            teardown()
            if reopens.count > 3 { close(); failed?(Failure(code: "mic", message: "The microphone keeps changing (\(why))")); return }
            do { try begin(why: why) } catch let f as Failure { close(); failed?(f) } catch { close(); failed?(Failure(code: "mic", message: error.localizedDescription)) }
        }
    }

    func stop() {
        DispatchQueue.main.async { [self] in
            guard running, !holding else { return }
            if hold, device?.bluetooth == true {
                sink = nil
                holding = true
                held = self
                emit("mic-held", ["name": device?.name ?? ""])
                // (never held long: the app releases it once the answer is said)
                let w = DispatchWorkItem { [weak self] in self?.release() }
                releaseAt = w
                DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: w)
                return
            }
            close()
        }
    }
    func release() {
        guard holding else { return }
        emit("mic-released", ["name": device?.name ?? ""])
        close()
    }
    func teardown() {
        if let (id, l) = rateListener {
            var a = address(kAudioDevicePropertyNominalSampleRate)
            AudioObjectRemovePropertyListenerBlock(id, &a, DispatchQueue.main, l)
        }
        rateListener = nil
        if let u = unit {
            AudioOutputUnitStop(u)
            AudioUnitUninitialize(u)
            AudioComponentInstanceDispose(u)
        }
        unit = nil
    }
    func close() {
        releaseAt?.cancel()
        teardown()
        running = false
        holding = false
        sink = nil
        Microphone.open.removeAll { $0 === self }
        if held === self { held = nil }
    }
}
/// The Bluetooth mic kept open after its session, until the app says the answer is over.
var held: Microphone?

#if PARAKEET
/// Parakeet (parakeet-unified-en-0.6b's GGUF) through transcribe.cpp in two passes, as Hex and Handy get their accuracy:
/// a streaming pass shows the words as they come (pending), then the whole utterance again, offline, is the final text.
final class Parakeet: Engine {
    static var model: OpaquePointer?
    static var session: OpaquePointer?
    static var loaded = ""
    /// One pass is this long at most: a longer run of speech without a pause is settled in parts.
    static let LONGEST = Int(RATE * 25)
    var active = false
    var shown = ""
    /// The utterance's audio, from just before it began, for the second pass.
    var heard: [Float] = []
    /// The last moment heard between utterances, for one starting again before the session stops feeding.
    var ring: [Float] = []

    init(model path: String) throws {
        if Parakeet.loaded != path {
            if let s = Parakeet.session { transcribe_session_free(s); Parakeet.session = nil }
            if let m = Parakeet.model { transcribe_model_free(m); Parakeet.model = nil }
            guard FileManager.default.fileExists(atPath: path) else { throw Failure(code: "model", message: "Parakeet's model isn't at \(path)") }
            emit(.loading("model"))
            _ = transcribe_init_backends_default()
            var m: OpaquePointer?
            var st = transcribe_model_load_file(path, nil, &m)
            guard st == TRANSCRIBE_OK, let model = m else { throw Failure(code: "model", message: "Parakeet's model didn't load: \(String(cString: transcribe_status_string(Int32(st.rawValue))))") }
            var s: OpaquePointer?
            st = transcribe_session_init(model, nil, &s)
            guard st == TRANSCRIBE_OK, let session = s else { transcribe_model_free(model); throw Failure(code: "model", message: "Parakeet couldn't start") }
            Parakeet.model = model
            Parakeet.session = session
            Parakeet.loaded = path
            // (silence through both passes once: Metal's kernels built and the weights read in now, not on the first words)
            let quiet = [Float](repeating: 0, count: Int(RATE * 0.6))
            begin()
            if active { _ = quiet.withUnsafeBufferPointer { transcribe_stream_feed(session, $0.baseAddress, Int32(quiet.count), nil) } }
            transcribe_stream_reset(session)
            active = false
            _ = quiet.withUnsafeBufferPointer { transcribe_run(session, $0.baseAddress, Int32(quiet.count), nil) }
        }
    }

    func begin() {
        guard let s = Parakeet.session, let m = Parakeet.model else { return }
        var params = transcribe_stream_params()
        transcribe_stream_params_init(&params)
        // (L, C, R) = 5.6 s / 160 ms / 160 ms: words 320 ms behind the voice (the model card's menu)
        var ext = transcribe_parakeet_buffered_stream_ext()
        transcribe_parakeet_buffered_stream_ext_init(&ext)
        ext.left_ms = 5600; ext.chunk_ms = 160; ext.right_ms = 160
        let ok = transcribe_model_accepts_ext_kind(m, TRANSCRIBE_EXT_SLOT_STREAM, TRANSCRIBE_EXT_KIND_PARAKEET_BUFFERED_STREAM)
        let st = withUnsafePointer(to: &ext) { e in
            e.withMemoryRebound(to: transcribe_ext.self, capacity: 1) { p in
                if ok { params.family = p }
                return transcribe_stream_begin(s, nil, &params)
            }
        }
        guard st == TRANSCRIBE_OK else { emit(.error(code: "engine", message: String(cString: transcribe_status_string(Int32(st.rawValue))))); return }
        active = true
        heard = []
    }

    /// The streaming pass's words so far, as pending.
    func publish() {
        guard let s = Parakeet.session else { return }
        var t = transcribe_stream_text()
        transcribe_stream_text_init(&t)
        guard transcribe_stream_get_text(s, &t) == TRANSCRIBE_OK else { return }
        let text = { (p: UnsafePointer<CChar>?, n: UInt64) -> String in p.flatMap { String(data: Data(bytes: $0, count: Int(n)), encoding: .utf8) } ?? "" }
        let now = (text(t.committed_text, t.committed_text_bytes) + text(t.tentative_text, t.tentative_text_bytes)).trimmingCharacters(in: .whitespaces)
        if now != shown { shown = now; emit(.pending(now, firm: 0)) }
    }

    func feed(_ pcm: [Float]) {
        guard !pcm.isEmpty else { return }
        if !active {
            ring.append(contentsOf: pcm)
            if ring.count > Session.PREROLL { ring.removeFirst(ring.count - Session.PREROLL) }
            return
        }
        guard let s = Parakeet.session else { return }
        heard.append(contentsOf: pcm)
        let st = pcm.withUnsafeBufferPointer { transcribe_stream_feed(s, $0.baseAddress, Int32(pcm.count), nil) }
        if st != TRANSCRIBE_OK { emit(.error(code: "engine", message: String(cString: transcribe_status_string(Int32(st.rawValue))))); active = false; return }
        publish()
        if heard.count >= Parakeet.LONGEST { commit(); begin() }
    }
    func speech() {
        guard !active else { return }
        begin()
        let r = ring
        ring = []
        if active { feed(r) }
    }
    /// The second pass: the utterance's audio whole, offline, as the final words (the pending ones go).
    func commit() {
        guard active, let s = Parakeet.session else { return }
        transcribe_stream_reset(s)
        active = false
        ring = []
        let audio = heard
        heard = []
        let st = audio.withUnsafeBufferPointer { transcribe_run(s, $0.baseAddress, Int32(audio.count), nil) }
        let text = st == TRANSCRIBE_OK ? (transcribe_full_text(s).map { String(cString: $0) } ?? "").trimmingCharacters(in: .whitespacesAndNewlines) : ""
        if st != TRANSCRIBE_OK { emit(.error(code: "engine", message: String(cString: transcribe_status_string(Int32(st.rawValue))))) }
        if !text.isEmpty { emit(.final(text)) }
        if !shown.isEmpty { shown = ""; emit(.pending("", firm: 0)) }
    }
    func pause() { commit() }
    func finish(_ done: @escaping () -> Void) {
        commit()
        done()
    }
}
#endif

// MARK: - Commands

func makeEngine(_ cmd: [String: Any]) -> () async throws -> Engine {
    let engine = cmd["engine"] as? String ?? "apple"
    let language = cmd["language"] as? String ?? ""
    let model = cmd["model"] as? String ?? ""
    let words = cmd["words"] as? [String] ?? []
    let here = makeLocal(engine: engine, language: language, model: model, words: words)
    // (the cloud first when its key came: this Mac's engine takes over should it fail)
    if let c = cmd["cloud"] as? [String: Any], let u = (c["url"] as? String).flatMap(URL.init(string:)), let key = c["key"] as? String, !key.isEmpty {
        let languages = c["languages"] as? [String] ?? [], model = c["model"] as? String ?? "stt-rt-v6"
        let name = c["name"] as? String ?? "Soniox"
        return { SonioxStream(url: u, key: key, model: model, languages: languages, words: words, name: name, here: "this Mac", tell: emit, local: here) }
    }
    return here
}

func makeLocal(engine: String, language: String, model: String, words: [String]) -> () async throws -> Engine {
    return {
        if engine == "parakeet" {
            #if PARAKEET
            return try Parakeet(model: model)
            #else
            throw Failure(code: "unsupported", message: "This build has no Parakeet")
            #endif
        }
        #if false
        guard #available(macOS 26.0, *) else { throw Failure(code: "unsupported", message: "Apple's dictation needs macOS 26") }
        return try await Apple(language: language, words: words, tell: emit)
        #else
        throw Failure(code: "unsupported", message: "Apple's dictation needs macOS 26")
        #endif
    }
}

func check(_ language: String) async -> [String: Any] {
    var o: [String: Any] = [:]
    #if PARAKEET
    o["parakeet"] = true
    #else
    o["parakeet"] = false
    #endif
    #if false
    if #available(macOS 26.0, *) {
        let loc = await Apple.locale(language)
        o["apple"] = loc != nil
        if let loc { o["locale"] = loc.identifier }
    } else {
        o["apple"] = false
    }
    #else
    o["apple"] = false
    #endif
    return o
}

/// What the microphone heard: kept for replaying it (the setting Keep the last dictation's audio), and told as it comes,
/// 16-bit at 16 kHz, when `tap` (the companion's realtime voice hears it too).
func kept(_ recording: AVAudioFile?, tap: Bool) -> (([Float]) -> Void)? {
    guard recording != nil || tap else { return nil }
    return { pcm in
        if let f = recording, let b = buffer16k(pcm) { try? f.write(from: b) }
        guard tap else { return }
        var d = Data(count: pcm.count * 2)
        d.withUnsafeMutableBytes { raw in
            let o = raw.bindMemory(to: Int16.self)
            for (i, x) in pcm.enumerated() { o[i] = Int16(max(-1, min(1, x)) * 32767).littleEndian }
        }
        emit("audio", ["data": d.base64EncodedString()])
    }
}

var current: Session?

func handle(_ cmd: [String: Any]) {
    switch cmd["cmd"] as? String {
    case "start":
        let begin = {
            sessionId = cmd["id"] as? Int ?? 0
            started = Date()
            // (a file instead of the microphone: a test of the app, heard as if said, then stopped as if by the user)
            var s: Session!
            let source: Source
            if let f = cmd["file"] as? String {
                source = FileSource(URL(fileURLWithPath: f), fast: false) { s.stop("stop") }
            } else {
                // (the mic the app picked, then the ones to take should it go; a held one on the same is taken on)
                let want = (cmd["mic"] as? [String] ?? []).filter { !$0.isEmpty }
                let mic: Microphone
                if let h = held, h.want == want { mic = h } else { held?.close(); mic = Microphone(want: want) }
                held = nil
                mic.hold = cmd["hold"] as? Bool ?? false
                mic.failed = { f in s.work.async { s.fail(f) } }
                source = mic
            }
            s = Session(source: source, silence: cmd["silence"] as? Double ?? 0, tell: emit)
            var recording: AVAudioFile?
            if let path = cmd["record"] as? String, !path.isEmpty {
                try? FileManager.default.removeItem(atPath: path)
                recording = try? AVAudioFile(forWriting: URL(fileURLWithPath: path), settings: mono16k.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            }
            s.onAudio = kept(recording, tap: cmd["tap"] as? Bool ?? false)
            current = s
            s.onEnd = { DispatchQueue.main.async { if current === s { current = nil } } }
            s.start(make: makeEngine(cmd))
        }
        // (the one under way ends first, its last events its own)
        guard let old = current else { return begin() }
        current = nil
        old.onEnd = { DispatchQueue.main.async(execute: begin) }
        old.stop("cancel")
    case "stop": current?.stop("stop")
    case "cancel": current?.stop("cancel")
    // (hands-free: only a press stops it)
    case "free": if let s = current { s.work.async { s.silenceMs = 0 } }
    // (the answer said: the Bluetooth mic held after its session closes)
    case "release": held?.release()
    case "devices": tellDevices()
    case "check":
        let language = cmd["language"] as? String ?? ""
        Task { emit("engines", await check(language)) }
    default: break
    }
}

let args = Array(CommandLine.arguments.dropFirst())
func arg(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }

if let file = arg("--file") {
    // A test: the file through the same session, then out.
    var cmd: [String: Any] = ["engine": arg("--engine") ?? "apple", "language": arg("--language") ?? "", "model": arg("--model") ?? "",
                              "words": (arg("--words") ?? "").split(separator: ",").map(String.init)]
    cmd["cmd"] = "start"
    // (`--cloud '{"url":…,"key":…}'`: Soniox's, or a stand-in for it)
    if let c = arg("--cloud"), let d = c.data(using: .utf8) { cmd["cloud"] = try? JSONSerialization.jsonObject(with: d) }
    var session: Session!
    let src = FileSource(URL(fileURLWithPath: file), fast: args.contains("--fast")) { session.stop("stop") }
    session = Session(source: src, silence: 0, tell: emit)
    session.onAudio = kept(nil, tap: args.contains("--tap"))
    session.onEnd = { exit(0) }
    session.start(warm: args.contains("--warm"), make: makeEngine(cmd))
    dispatchMain()
}

emit("ready")
tellDevices()
watchDevices()
Thread.detachNewThread {
    while let line = readLine() {
        guard let d = line.data(using: .utf8), let cmd = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { continue }
        DispatchQueue.main.async { handle(cmd) }
    }
    // (stdin closed: the app is gone, and the microphone with it)
    DispatchQueue.main.async {
        guard let s = current else { exit(0) }
        s.onEnd = { exit(0) }
        s.stop("cancel")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { exit(0) }
    }
}
dispatchMain()
