import Foundation

/// What hears a voice note live, as the server says (GET dictation/cloud?for=phone, plugins/core/dictation): a cloud
/// recognizer in Soniox's protocol when it gives one (Soniox's, or its own relay), this iPhone's after it or instead.
struct Hearer {
    /// What the user knows it as: "Soniox", "On this iPhone".
    let name: String
    let words: LiveWords
    let make: (@escaping Tell) async throws -> Engine

    static let here = "On this iPhone"

    /// Never waits long: what's heard meanwhile waits in the Session for it.
    static func ask() async -> Hearer {
        let answer = (try? await Servers.call("GET", "dictation/cloud?for=phone", timeout: 4)) ?? [:]
        let terms = (answer["terms"] as? [Any] ?? []).compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let words = Array(NSOrderedSet(array: terms.map { String($0.prefix(100)) }).array.compactMap { $0 as? String }.prefix(100))
        let swaps = LiveWords(replacements: answer["replacements"] as? [[Any]] ?? [])
        let local = { (tell: @escaping Tell) async throws -> Engine in
            #if false
            if #available(iOS 26.0, *) {
                return try await Apple(language: "", words: words, tell: tell)
            }
            #endif
            throw Servers.Failure("Local dictation is not available on this iOS version")
        }
        guard let key = answer["key"] as? String, !key.isEmpty, let to = answer["url"] as? String, let url = socket(to) else {
            return Hearer(name: here, words: swaps, make: local)
        }
        // (a path is the server's relay, to whichever recognizer it's set to)
        let name = answer["name"] as? String ?? (URL(string: to)?.host == nil ? "Your server" : "Soniox")
        let model = answer["model"] as? String ?? "stt-rt-v6"
        let languages = languagesOf(answer["languages"] as? [String] ?? [])
        return Hearer(name: name, words: swaps) { tell in
            SonioxStream(url: url, key: key, model: model, languages: languages, words: words, name: name, here: "this iPhone",
                         tell: tell, local: { try await local(tell) })
        }
    }

    /// The socket's address: a path is the server's own (its relay).
    private static func socket(_ to: String) -> URL? {
        guard let server = Servers.current, let base = URL(string: server.url),
              var parts = URL(string: to, relativeTo: base).flatMap({ URLComponents(url: $0.absoluteURL, resolvingAgainstBaseURL: false) }) else { return nil }
        if parts.scheme == "https" { parts.scheme = "wss" } else if parts.scheme == "http" { parts.scheme = "ws" }
        return parts.url
    }

    /// The languages it's told to expect (it switches between them on its own): the server's, else this iPhone's.
    private static func languagesOf(_ said: [String]) -> [String] {
        let all = said.isEmpty ? Locale.preferredLanguages : said
        let codes = all.compactMap { $0.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() } }
            .filter { (2...3).contains($0.count) && $0.allSatisfy(\.isLetter) }
        return Array(NSOrderedSet(array: codes).array.compactMap { $0 as? String }.prefix(6))
    }
}

/// The words as heard: settled ones and the pending few after them, with the dictionary's replacements made as on
/// the Mac (core/dictationtext.ts).
struct LiveWords {
    var settled = ""
    var pending = ""
    /// The characters at the end that may still change (pending words not yet final).
    private(set) var loose = 0
    private var swaps: [(NSRegularExpression, String)] = []

    init(replacements: [[Any]] = []) {
        swaps = replacements.compactMap { pair in
            guard pair.count >= 2, let said = (pair[0] as? String)?.trimmingCharacters(in: .whitespaces),
                  let written = (pair[1] as? String)?.trimmingCharacters(in: .whitespaces), !said.isEmpty, !written.isEmpty else { return nil }
            let words = said.split(whereSeparator: \.isWhitespace).map { NSRegularExpression.escapedPattern(for: String($0)) }
            let pattern = "(?<![\\p{L}\\p{N}@])" + words.joined(separator: "\\s+") + "(?![\\p{L}\\p{N}])"
            guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
            return (re, NSRegularExpression.escapedTemplate(for: written))
        }
    }

    mutating func settle(_ text: String) { settled = Self.join(settled, swapped(text)) }
    mutating func show(_ text: String, firm: Int) {
        pending = swapped(text)
        loose = min(pending.count, swapped(String(text.dropFirst(firm))).count)
    }
    mutating func replace(_ text: String) {
        settled = text
        pending = ""
        loose = 0
    }
    var all: String { Self.join(settled, pending) }

    private func swapped(_ text: String) -> String {
        swaps.reduce(text) { t, s in s.0.stringByReplacingMatches(in: t, range: NSRange(t.startIndex..., in: t), withTemplate: s.1) }
    }

    /// `text` said after `before`: a space between words, none before punctuation or at the start.
    static func join(_ before: String, _ text: String) -> String {
        let t = text.drop(while: \.isWhitespace)
        guard let first = t.first else { return before }
        guard let last = before.last, !last.isWhitespace, !"([{\"'“‘/-".contains(last), !".,!?;:…)]}\"'”’".contains(first) else { return before + t }
        return before + " " + t
    }
}
