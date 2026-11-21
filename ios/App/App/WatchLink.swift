import AVFoundation
import Speech
import UIKit
import WatchConnectivity

/// The watch's way to the server, which it can't reach itself: it asks the phone (WatchConnectivity), which asks the
/// server it opened last. The watch's side: Watch/PhoneLink.swift.
final class WatchLink: NSObject, WCSessionDelegate {
    static let shared = WatchLink()

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { await Voice.retry() }
        }
    }

    /// With the watch app there, ask for speech recognition now, while the app is in front: a voice note wakes it in
    /// the background, where it can't ask (the older recognizer needs it; SpeechTranscriber doesn't).
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        guard state == .activated, session.isWatchAppInstalled, SFSpeechRecognizer.authorizationStatus() == .notDetermined else { return }
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active { SFSpeechRecognizer.requestAuthorization { _ in } }
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() } // another watch was paired

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let task = UIApplication.shared.beginBackgroundTask(withName: "watch")
        Task {
            replyHandler(await self.handle(message))
            await UIApplication.shared.endBackgroundTask(task)
        }
    }

    /// `do: wake`, sent without waiting for an answer: being woken was the point.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {}

    /// A short voice note, as the message itself (the phone is near): its outcome is the answer (JSON: the keys a file's
    /// outcome has).
    func session(_ session: WCSession, didReceiveMessageData data: Data, replyHandler: @escaping (Data) -> Void) {
        let id = UUID().uuidString
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(id).m4a")
        let task = UIApplication.shared.beginBackgroundTask(withName: "voice")
        Task {
            var outcome: [String: Any] = ["voice": id]
            do {
                try data.write(to: url)
                outcome.merge(await Voice.send(url, from: "Apple Watch")) { $1 }
            } catch {
                outcome["error"] = Servers.say(error)
            }
            replyHandler((try? JSONSerialization.data(withJSONObject: outcome)) ?? Data())
            await UIApplication.shared.endBackgroundTask(task)
        }
    }

    private func handle(_ m: [String: Any]) async -> [String: Any] {
        do {
            switch m["do"] as? String {
            case "inbox":
                let r = try await Servers.call("GET", "inbox/events?open=1&limit=30", from: "watch")
                // (what's in the inbox: not what's done, nor snoozed)
                let events = (r["events"] as? [[String: Any]] ?? []).filter { $0["state"] as? String != "done" && $0["snoozed"] == nil }.map { e in
                    // Only what a message carries (plist values: no JSON nulls).
                    e.filter { ["id", "title", "body", "preview", "kind", "state", "ask", "read", "t", "terminal", "session", "host"].contains($0.key) && !($0.value is NSNull) }
                }
                return ["events": events, "unread": r["unread"] as? Int ?? 0, "needs": r["needs"] as? Int ?? 0]
            case "answer":
                guard let id = m["id"] as? String, let answer = m["answer"] as? String else { return ["error": "Nothing to answer"] }
                return ["ok": true, "text": try await Push.answer(id, answer, text: m["text"] as? String)]
            default:
                return ["ok": true]
            }
        } catch {
            return ["error": Servers.say(error)]
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard file.metadata?["do"] as? String == "voice", let id = file.metadata?["id"] as? String else { return }
        let trim = file.metadata?["trim"] as? Double ?? 0
        // The file is gone when this returns: keep it until it's transcribed.
        let kept = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(id).m4a")
        try? FileManager.default.removeItem(at: kept)
        do { try FileManager.default.moveItem(at: file.fileURL, to: kept) } catch {
            Self.reply(["voice": id, "error": Servers.say(error)])
            return
        }
        let task = UIApplication.shared.beginBackgroundTask(withName: "voice")
        Task {
            if trim > 0 { await Voice.trim(kept, by: trim) }
            var outcome: [String: Any] = ["voice": id]
            outcome.merge(await Voice.send(kept, from: "Apple Watch")) { $1 }
            Self.reply(outcome)
            await UIApplication.shared.endBackgroundTask(task)
        }
    }

    /// A voice note's outcome: straight back while the watch is near, else queued (watchOS hands it over when it likes).
    static func reply(_ outcome: [String: Any]) {
        let s = WCSession.default
        guard s.isReachable else { s.transferUserInfo(outcome); return }
        s.sendMessage(outcome, replyHandler: nil) { _ in s.transferUserInfo(outcome) }
    }
}

/// A recording on its way to the inbox, never lost: with its words (heard live, or transcribed here when short), else as
/// is for the server. It waits in Application Support/Voice notes, its words beside it, until sent.
@MainActor
enum Voice {
    /// Longer than this, the server transcribes it: here it'd outlast what iOS gives an app in the background.
    static let longest: TimeInterval = 180
    private static let waiting = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Voice notes", isDirectory: true)
    /// The ones being sent now (by send or retry: never both).
    private static var sending = Set<String>()

    /// Send it on; the file is taken. `text`: its words, heard as it was recorded. Its outcome: `text` (what was said,
    /// or where it is), `path` and `terminal` when its words went with it, `error` when it couldn't even be kept.
    static func send(_ file: URL, from: String, text: String? = nil) async -> [String: Any] {
        let client = from == "Apple Watch" ? "watch" : "iphone"
        let url = waiting.appendingPathComponent("\(client)-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString).\(file.pathExtension)")
        do {
            try FileManager.default.createDirectory(at: waiting, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: file, to: url)
        } catch {
            return ["error": Servers.say(error)]
        }
        sending.insert(url.lastPathComponent)
        defer { sending.remove(url.lastPathComponent) }
        var said = text
        if said == nil {
            let seconds = (try? AVAudioFile(forReading: url)).map { Double($0.length) / $0.fileFormat.sampleRate } ?? 0
            if seconds > 0, seconds <= longest { said = try? await Transcribe.file(url) }
        }
        if let said { try? said.write(to: wordsOf(url), atomically: true, encoding: .utf8) }
        do {
            let r = try await deliver(url)
            guard let said, let r else { return ["text": "Sent to your server to transcribe: it'll be in your inbox"] }
            var out: [String: Any] = ["text": said, "path": r["path"] as? String ?? ""]
            if let t = r["terminal"] as? String { out["terminal"] = t }
            return out
        } catch {
            return ["text": "Kept on your iPhone: it's sent when Vaultite next opens (\(Servers.say(error)))"]
        }
    }

    /// Send the recordings still waiting, oldest first; what still can't go stays.
    static func retry() async {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: waiting.path) else { return }
        for name in names.sorted() where !name.hasPrefix(".") && !name.hasSuffix(".txt") && !sending.contains(name) {
            sending.insert(name)
            defer { sending.remove(name) }
            do { try await deliver(waiting.appendingPathComponent(name)) } catch { return }
        }
    }

    /// Cut its last `seconds` (the silence a watch note stopped itself after); left whole when that fails.
    static func trim(_ url: URL, by seconds: Double) async {
        let asset = AVURLAsset(url: url)
        guard let length = try? await asset.load(.duration).seconds, length > seconds,
              let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return }
        let out = url.deletingLastPathComponent().appendingPathComponent("trimmed-\(url.lastPathComponent)")
        export.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: length - seconds, preferredTimescale: 600))
        do {
            try await export.export(to: out, as: .m4a)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: out)
        } catch {
            try? FileManager.default.removeItem(at: out)
        }
    }

    private static func wordsOf(_ url: URL) -> URL { url.appendingPathExtension("txt") }

    /// To the server with its words when they're known, else as it is for the server to transcribe; then gone from here.
    /// The inbox's answer when its words went.
    @discardableResult
    private static func deliver(_ url: URL) async throws -> [String: Any]? {
        let watch = url.lastPathComponent.hasPrefix("watch-")
        let from = watch ? "Apple Watch" : "iPhone", client = watch ? "watch" : "iphone"
        let words = wordsOf(url)
        if let text = try? String(contentsOf: words, encoding: .utf8) {
            do {
                let r = try await Servers.send("ops/inbox.voice", file: url, query: ["text": text, "from": from, "ext": url.pathExtension], from: client)
                for f in [url, words] { try? FileManager.default.removeItem(at: f) }
                return r
            } catch let e as Servers.Failure where e.status != 0 {
                // (the server refused it with its words: it transcribes the recording itself)
                try? FileManager.default.removeItem(at: words)
            }
        }
        _ = try await Servers.send("audio-recorder/voice", file: url, query: ["ext": url.pathExtension, "from": from], from: client)
        try? FileManager.default.removeItem(at: url)
        return nil
    }
}

/// What a recording says, transcribed on this phone.
enum Transcribe {
    static func file(_ url: URL) async throws -> String {
        let text: String
        // Its model not there and not downloadable now (no network, a simulator): the older recognizer.
        do { text = try await analyzer(url) } catch { text = try await recognizer(url) }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { throw Servers.Failure("Nothing was heard") }
        return t
    }

    private static func analyzer(_ url: URL) async throws -> String {
        return try await recognizer(url)
    }

    /// A language SpeechTranscriber hasn't, or its model missing: the older recognizer, on the device when it can.
    private static func recognizer(_ url: URL) async throws -> String {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw Servers.Failure("Open Vaultite on your iPhone and allow speech recognition")
        }
        guard let recognizer = SFSpeechRecognizer() ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
            throw Servers.Failure("Speech recognition isn't available now")
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request.addsPunctuation = true
        return try await withCheckedThrowingContinuation { c in
            var done = false
            recognizer.recognitionTask(with: request) { result, error in
                if done { return }
                if let error { done = true; return c.resume(throwing: error) }
                if let result, result.isFinal { done = true; c.resume(returning: result.bestTranscription.formattedString) }
            }
        }
    }
}
