import { execFileSync, spawn } from "node:child_process"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import type { Any, VaultTest } from "./harness.ts"
import { waitFor } from "../lib.ts"
import { agentLine, request, where } from "../fakes.ts"
import type { JobEvent } from "../../../plugins/core/companion/joblife.ts"
import { portOf } from "../../../core/listening.ts"
import { jobSite } from "./jobsite.ts"
export default async ($: VaultTest) => {
  // (the companion acting: its own tool call, not any agent's vau)
  const { asItsTool } = await import("../../../plugins/core/companion/chat.ts")
  const { VAULT, api, app, check } = $
  const J = await import("../../../plugins/core/companion/jobs.ts")
  const L = await import("../../../plugins/core/companion/joblife.ts")
  const { jobTold } = await import("../../../core/desktop/jobnews.ts")
  const W = await import("../../../plugins/core/companion/where.ts")

  // The lifecycle: one table, every move logged, nothing out of stopped.
  {
    const job = (): Any => ({ id: "j1", title: "t", state: "starting", where: { machine: "", label: "M", cwd: "/r", repo: "r", agent: "claude", account: "", harness: "Claude Code", model: "", effort: "", why: "" },
      terminal: "claude-x", now: "", started: 0, turn: 0, at: 0, seen: true, log: [] })
    const run = (evs: JobEvent[]) => { const j = job(); for (const e of evs) L.step(j, e, 1); return j }
    {
      // (what each summoned ask is told of its jobs: the newest few, and every one waiting on them however old)
      const now = 10 * 3600_000, at = (id: string, state: string, h: number) => ({ ...job(), id, title: id, state, at: now - h * 3600_000, started: now - h * 3600_000 })
      const line = J.jobsLine([at("ja", "working", 0), at("jb", "done", 0.1), at("jc", "done", 0.2), at("jd", "done", 0.3), at("je", "done", 0.4), at("jold", "ready for review", 8), at("jgone", "done", 9)], now)
      check("jobs line: a job ready for review is always listed, past the newest few", /jold "jold" \(ready for review/.test(line) && !/je "je"/.test(line) && !/jgone/.test(line), line)
    }
    const a = run(["working", "asks", "working", "changed"]), b = run(["working", "stop", "working", "told"]), c = run(["working", "answered", "told", "changed", "stop"])
    check("jobs: the lifecycle moves by its table, each move logged (starting, working, needs you, ready for review), new once it needs the user",
      a.state === "ready for review" && a.log.map((x: Any) => x.to).join() === "working,needs you,working,ready for review" && a.seen === false && J.unseen(a), a.log)
    {
      const w = run(["working"]), card = J.cardOf({ ...w, unreachable: "the terminal server (pid 9) hasn't answered since 15:48:02" })
      check("jobs: one whose terminal can't be reached shows waiting with why, not working", card.state === "waiting" && /^Can't be reached: the terminal server/.test(card.now) &&
        J.cardOf(w).state === "working", card)
    }
    {
      const d = run(["working", "answered"]), was = { state: d.state, turn: d.turn, now: d.now, at: d.at }, x = L.step(d, "told", 5)!
      const back = L.untell(d, x, was), e = run(["working", "answered"]), y = L.step(e, "told", 5)!
      L.step(e, "asks", 6)
      check("jobs: a told its terminal didn't take is taken back, its log too; one moved since stays as it moved",
        back?.from === "working" && back.to === "done" && d.state === "done" && d.log.at(-1).ev === "answered" && L.untell(e, y, was) === null && e.state === "needs you", [d.log, e.log])
    }
    check("jobs: nothing moves a stopped job; a reviewed one stopped is done", b.state === "stopped" && b.log.length === 2 && c.state === "done" && c.log.at(-1).ev === "stop", [b.log, c.log])
    check("jobs: a worker that ends while it works failed; one ready for review that ends is done",
      run(["working", "ended"]).state === "failed" && run(["working", "changed", "ended"]).state === "done" && run(["ended"]).state === "failed")
    check("jobs: one that landed its own change is done, ready for review or still working",
      run(["working", "changed", "landed"]).state === "done" && run(["working", "landed"]).state === "done")
    const said = ["A job's proof is now a video, and it's pushed to main as 98b7fcde.", "It's on main as `08f5dfd`; the M1 picks it up.", "All three are done.\n\n- **Merged:** `c09009af feat: x` is on main.",
      "Landed on main as c09009af. Now cleanup.", "Both fixes are on main as ff4071ef: CI passed."]
    const unsaid = ["Committed as a8ef2daa on branch job-x, but **not pushed**: waiting for your Keep and merge.", "Once it's on main, the M1 picks it up.", "I didn't push to main.",
      "The M1 takes it from main.", "Made the heading blue. Try http://localhost:5173."]
    check("jobs: a worker's words saying it landed its change on main, never ones that only might", said.every(J.landedSaid) && !unsaid.some(J.landedSaid), [said.filter((t) => !J.landedSaid(t)), unsaid.filter(J.landedSaid)])
    check("jobs: the commits a message names", J.commitsIn("pushed as 7493dcf6 (`c09009afa67159e`), see #12345678 and abcdefgh, deadbeef").join() === "7493dcf6,c09009afa67159e", J.commitsIn("pushed as 7493dcf6 (`c09009afa67159e`), see #12345678 and abcdefgh, deadbeef"))
    {
      // (a turn at rest: its background tasks running hold it working, and one landing itself until it says how that went)
      const aw = { on: "npm run verify", since: Date.parse("2026-11-17T21:58:00Z"), n: 1 }
      const R = (o: Any) => L.restEvent({ landed: false, changes: true, text: "Fixed it.", at: 0, now: 1000, ...o })
      check("jobs: a turn ending with its background tasks running stays working; one landing itself is never ready for review before it says Merged or Not merged",
        R({ awaits: aw }) === "working" && R({ awaits: { ...aw, n: 2 }, changes: false }) === "working" && R({ awaits: aw, landed: true }) === "landed" &&
        R({}) === "changed" && R({ changes: false }) === "answered" && R({ landed: true }) === "landed" &&
        R({ lands: true, text: "Verify is still running in the background. When it's done I'll land the fix." }) === "working" &&
        R({ lands: true, text: "Not merged: verify fails on main too." }) === "changed" && R({ lands: true, now: L.LAND_WAIT + 1 }) === "changed" &&
        R({ lands: true, changes: false, text: "Nothing to change." }) === "answered")
      const j = { title: "t", turn: 0, now: "", last: { text: "Still running local verify before the try.", at: 5, awaits: aw } }
      check("jobs: at rest with a background task, its now-line says what it waits on and since when; working, what it says",
        /^Waiting on npm run verify, since \S/.test(J.nowOf(j, { state: "idle" })) &&
        J.nowOf({ ...j, last: { ...j.last, awaits: { ...aw, n: 3 } } }, { state: "done" }).startsWith("Waiting on npm run verify and 2 more, since") &&
        J.nowOf(j, { state: "working" }) === "Still running local verify before the try.", J.nowOf(j, { state: "idle" }))
    }
    const E = (text: boolean, final: boolean, changes: boolean, crashed: boolean) => L.endEvent({ text, final, changes, crashed })
    check("jobs: a terminal ending after its worker left an answer is done (with changes, ready for review), mid-turn too unless it crashed; with nothing, failed",
      E(true, false, false, false) === "answered" && E(true, true, true, true) === "changed" && E(false, false, true, false) === "changed" &&
      E(true, false, false, true) === "ended" && E(false, false, false, false) === "ended")
    check("jobs: every state is in the table, and each one reached is one of them", J.JOB_STATES.every((s) => s in L.JOB_NEXT) &&
      Object.values(L.JOB_NEXT).every((m) => Object.values(m).every((s) => J.JOB_STATES.includes(s!))))
    check("jobs: its news in a line said aloud: needs you, ready for review, done, failed; a reviewed job done isn't news again",
      J.jobSpoken({ title: "Make the header blue on the about page please", state: "ready for review" }, "working") === 'The job "Make the header blue" is ready for review.' &&
      J.jobSpoken({ title: "x", state: "needs you" }, "working") === 'The job "x" needs you.' && J.jobSpoken({ title: "", state: "failed" }, "working") === "A job failed." &&
      J.jobSpoken({ title: "x", state: "done" }, "ready for review") === "" && J.jobSpoken({ title: "x", state: "working" }, "starting") === "")
    check("jobs: notifications by job_news: needing you or failed, quiet or spoken, none when off; one ready or done knocks instead (its proof)",
      jobTold("needs you", "quiet") && jobTold("failed", "quiet") && !jobTold("done", "quiet") && !jobTold("ready for review", "quiet") &&
      !jobTold("done", "spoken") && !jobTold("ready for review", "spoken") && jobTold("failed", "spoken") && !jobTold("needs you", "off") && !jobTold("working", "spoken"))
    {
      const { jobNews } = await import("../../../electron/helperlogic.ts")
      const j = (state: string) => ({ id: "a", title: "x", state, link: null, unseen: true, at: 0 })
      check("jobs: the menu bar's notifications follow job_news",
        jobNews([j("working")], [j("done")], "quiet").length === 0 && jobNews([j("working")], [j("done")], "spoken").length === 0 &&
        jobNews([j("working")], [j("needs you")], "quiet").length === 1 && jobNews([j("working")], [j("failed")], "off").length === 0)
      const { jobNote } = await import("../../../electron/helperlogic.ts")
      const trust = { ...j("needs you"), waits: { question: "Trust this folder?", choices: ["Yes, I trust this folder", "No, exit"] } }
      const imports = { ...trust, waits: { question: "Allow external CLAUDE.md imports?", choices: ["Yes, allow external imports", "No, disable external imports"] } }
      check("jobs: a job waiting on a prompt is told with its question and its choices as buttons; another prompt after it is told again",
        jobNote(trust).body === "x\nTrust this folder?" && jobNote(trust).choices.join() === "Yes, I trust this folder,No, exit" && jobNote(j("done")).choices.length === 0 &&
        jobNews([trust], [imports], "quiet").length === 1 && jobNews([trust], [trust], "quiet").length === 0, jobNote(trust))
      const perm = { kind: "permission" as const, choices: ["Yes, I trust this folder", "No, exit"] }, q = { kind: "question" as const, choices: ["Local cert", "Let's Encrypt (Recommended)"] }
      check("jobs: a choice is named by its number, its words or their start, or yes and no for a permission",
        J.choiceIn(perm, "1") === 1 && J.choiceIn(perm, "No, exit") === 2 && J.choiceIn(perm, "yes") === 1 && J.choiceIn(perm, "No.") === 2 && J.choiceIn(perm, "Yes, I trust") === 1 &&
        J.choiceIn(perm, "maybe") === 0 && J.choiceIn(perm, "3") === 0 && J.choiceIn(q, "let's encrypt") === 2 && J.choiceIn(q, "yes") === 0)
    }
    {
      const site = { cwd: "/Users/alice/Projects/site", repo: "site", base: "0123456789abcdef", label: "M1", ...J.worktreeOf("/Users/alice/Projects/site", "site", "j3k9x2a") }
      const jt = J.jobTask("Fix the footer", undefined, site, "j3k9x2a")
      check("jobs: a worker is told to show its change working: a demo video recorded on its own copy, its befores, stills of the Mac's UI, by its job's id, in its report",
        jt.includes('vau companion tour-save "') && jt.includes("--job j3k9x2a") && jt.includes("--record <your own copy's address>") && /never their live app/.test(jt) &&
        jt.includes("(before: ") && jt.includes("(after: <png>)") && jt.includes("vau inbox report ... --video") && !J.jobTask("x", undefined, site).includes("tour-save"))
      const live = J.jobTask("Fix the footer", undefined, { ...site, live: true }, "j3k9x2a"), note = J.jobTask("Tidy my note", undefined, { ...site, repo: "", tree: undefined, branch: undefined })
      check("jobs: every coding job works in its own worktree and branch beside its checkout, made at the commit asked, its packages installed there; never the checkout",
        site.tree === "/Users/alice/Projects/site-j3k9x2a" && site.branch === "job-j3k9x2a" &&
        jt.includes("git -C /Users/alice/Projects/site worktree add /Users/alice/Projects/site-j3k9x2a -b job-j3k9x2a 0123456789ab") && /never in \/Users\/alice\/Projects\/site itself/.test(jt) &&
        /install them there/.test(jt) && /Keep and merge lands it/.test(jt) && /running server's own checkout/.test(live) && !/worktree/.test(note) && !/They asked over/.test(jt), jt)
      const lands = J.jobTask("Fix the footer", undefined, site, "j3k9x2a", { land: true }), watchedLand = J.jobTask("x", undefined, { ...site, watched: true }, "j3k9x2a", { land: true })
      check("jobs: with jobs_land, a coding job lands itself once its checks pass, from its worktree, cleaned up; it asks only on a real tradeoff; one over a watched preview doesn't",
        /land it yourself, from your worktree \/Users\/alice\/Projects\/site-j3k9x2a/.test(lands) && /worktree remove/.test(lands) && /"Merged:"/.test(lands) && /only on a real tradeoff/.test(lands) &&
        !/Keep and merge lands it/.test(lands) && lands.includes("tour-save") && !/land it yourself/.test(watchedLand) && !/land it yourself/.test(note), lands)
      const always = J.jobTask("Fix the footer", undefined, site, "j3k9x2a", { land: true, proof: "always" }), never = J.jobTask("Fix the footer", undefined, site, "j3k9x2a", { land: true, proof: "never" })
      const reviewNever = J.jobTask("Fix the footer", undefined, site, "j3k9x2a", { proof: "never" }), noteAuto = J.jobTask("Tidy my note", undefined, { ...site, repo: "", tree: undefined, branch: undefined }, "j3k9x2a", { land: true })
      check("jobs: jobs_proof auto records a video only for a job ending in review; one landing itself saves its tour unrecorded, played live once on main (a video if it doesn't land); always records; never, no proof",
        lands.includes("--job j3k9x2a --open") && !lands.includes("--record <your own copy's address>") && /with no --record/.test(lands) && /Should it not land[^]*record its video/.test(lands) &&
        !lands.includes("--video") && /checks pass and its tour is saved, land it yourself/.test(lands) &&
        jt.includes("--record <your own copy's address>") && noteAuto.includes("--record <your own copy's address>") &&
        always.includes("--record <your own copy's address>") && /checks pass and your demo is recorded, land it yourself/.test(always) && always.includes("vau inbox report ... --video") &&
        !never.includes("tour-save") && /checks pass, land it yourself/.test(never) && !reviewNever.includes("tour-save") && /Keep and merge lands it/.test(reviewNever), lands)
      check("jobs: a worker writes plain sentences and shows a UI as real pictures (vau html picture, embedded), never ASCII; one over a watched preview isn't told",
        [jt, note].every((t) => /plain, short sentences/.test(t) && t.includes("vau html picture") && /Never ASCII art/.test(t)) && !J.jobTask("x", undefined, { ...site, watched: true }, "j3k9x2a").includes("vau html picture"), note)
      const moved = J.jobTask("Fix the footer", undefined, { ...site, moved: "the preview http://localhost:5173 on M4" }, "j3k9x2a")
      const over = { cwd: site.cwd, repo: "site", label: "M4", preview: "http://localhost:5173" }
      const watching = J.jobTask("Make the heading blue", undefined, { ...over, watched: true }, "j3k9x2a")
      check("jobs: one over a preview they watch edits the checkout serving it, fast, no worktree, no demo; the live server's own or one moved elsewhere isn't",
        J.inPlace(over) && !J.inPlace({ ...over, live: true }) && !J.inPlace({ ...over, moved: "the preview on M4" }) && !J.inPlace({ ...over, preview: undefined }) && !J.inPlace({ ...over, repo: "" }) &&
        /They watch http:\/\/localhost:5173 reload as you change \/Users\/alice\/Projects\/site[^]*no worktree/.test(watching) && !/worktree add/.test(watching) && !watching.includes("tour-save"), watching)
      check("jobs: one moved to another machine works in its worktree there too, previewed there", /worktree add/.test(moved) && /fetch that commit first/.test(moved) && /They asked over the preview http:\/\/localhost:5173 on M4\. You run on M1/.test(moved), moved)
      const land = J.landTask(site), liveLand = J.landTask({ ...site, live: true }), old = J.landTask({ cwd: "/r" })
      check("jobs: Keep and merge lands it from its worktree (pushed to main, nothing merged in the checkout), then removes the worktree and its branch; one line",
        /merge it now, from your worktree \/Users\/alice\/Projects\/site-j3k9x2a \(branch job-j3k9x2a\), as this repo's own rules say/.test(land) && /git push origin HEAD:main/.test(land) &&
        land.includes("git -C /Users/alice/Projects/site worktree remove /Users/alice/Projects/site-j3k9x2a, and branch -D job-j3k9x2a") && /Never switch or edit \/Users\/alice\/Projects\/site:/.test(land) && !land.includes("\n") &&
        /nothing lands there/.test(liveLand) && /the server takes main itself/.test(liveLand) && /don't merge/.test(liveLand) && !/worktree/.test(old) && /^They watched your change and kept it: merge it now, as this repo's own rules say/.test(old), land)
      const liveLands = J.jobTask("Fix the footer", undefined, { ...site, live: true }, "j3k9x2a", { land: true })
      check("jobs: one landing where its server takes main pushes and ends saying its commit, never waiting for it to go live itself; fixed forward when CI is red",
        /don't wait yourself[^]*no vau version --wait/.test(liveLands) && /"Merged:" and its commit's hash on main/.test(liveLands) && !/don't wait yourself/.test(lands) &&
        /CI failed on 1a2b3c4d5e6f, the commit you landed[^]*worktree add -B job-j3k9x2a \/Users\/alice\/Projects\/site-j3k9x2a origin\/main[^]*gh run list --commit 1a2b3c4d5e6f7/.test(J.fixTask({ ...site, live: true }, "1a2b3c4d5e6f7", "CI failed on it")), liveLands)
      check("jobs: the commit a worker's Merged names, before any other its words name", J.mergedCommit("Rebased onto 7fba84d0. Merged: `c09009af` is on main.") === "c09009af" &&
        J.mergedCommit("Pushed as 98b7fcde.") === "98b7fcde" && J.mergedCommit("Merged.") === "")
      const first = J.lastOf({ text: "Fixed it. The links \"Why now?\" stay.\n\nShould I also change the header? Or keep it as is?", at: 5, final: true, prompt: jt })
      const told = J.lastOf({ text: "Looking at it.", at: 9, final: false, prompt: "Use the **darker** blue", awaits: { on: "npm run verify", since: 1, n: 2 } })
      check("jobs: its latest turn: what it said, the questions its answer ends with (quotes left out), what it was told after its task, its background tasks",
        first.text.startsWith("Fixed it.") && JSON.stringify(first.asks) === JSON.stringify(["Should I also change the header?", "Or keep it as is?"]) && first.told === undefined &&
        told.told === "Use the darker blue" && told.asks === undefined && told.awaits?.n === 2, [first, told])
      const j = { title: "Fix the footer", turn: 10_000, now: "starting", last: { text: "Checking the footer at phone width. Then the header.", at: 20_000 } }
      check("jobs: what it does now is what it waits on, else what it said last this turn, else its status (not its own title)",
        J.nowOf(j, {}) === "Checking the footer at phone width." && J.nowOf(j, { kind: "question", msg: "Which blue?" }) === "waits on an answer: Which blue?" &&
        J.nowOf({ ...j, turn: 30_000 }, { title: "✳ Fix the footer" }) === "starting" && J.nowOf({ ...j, turn: 30_000 }, { title: "✳ Editing a.ts" }) === "Editing a.ts")
      check("jobs: its conversation resumes in its account's terminal", J.resumeOf({ session: "s-123", where: where({ agent: "claude_agent" }) }) === "resume-claude_agent-s-123" &&
        J.resumeOf({ where: where({ agent: "claude" }) }) === "")
    }
    {
      const shot = "/Users/alice/Library/Application Support/Vaultite Main/screens/display-746-1794124886020.png", close = "/Users/alice/Library/Application Support/Vaultite Main/screens/close-746-1794124886021.png"
      const m: Any = { kind: "ask", t: 1, seq: 1, text: "what's this?", path: "Notes/Ideas.md", under: "a/b c", shot, closeUp: { shot, at: { x: 0, y: 0, width: 9, height: 9 }, scale: 3 } }
      const followed = J.followTask("Look again", { ...m, closeUp: { ...m.closeUp, shot: close } }), started = J.jobTask("Look", m)
      check("jobs: the pictures an ask hands a worker are found in what it's told (a path with spaces, on one line with the rest), each once",
        J.picturesIn(followed).join("|") === `${shot}|${close}` && J.picturesIn(started).join("|") === shot && !J.picturesIn("see /tmp/screens/other.png").length, [J.picturesIn(followed), followed])
    }
    check("jobs: a PR and a preview's link from the worker's last message", JSON.stringify(J.linksIn("Done. PR: https://github.com/lighthouse/site/pull/12, try http://localhost:5173/about.")) ===
      JSON.stringify({ pr: "https://github.com/lighthouse/site/pull/12", link: "http://localhost:5173/about" }) && J.linksIn("nothing", "https://m1.tail1.ts.net:8450").link === "https://m1.tail1.ts.net:8450")
  }

  // A turn's handoffs, said: one's own line (or its say); several, one line naming them, a sentence each kind.
  {
    const Told = await import("../../../plugins/core/companion/jobtold.ts")
    const T = (kind: Any, title: string, line = "", say = "") => ({ kind, title, line, say })
    check("handoffs said: one keeps its own line, or its say", Told.toldLine([T("follow", "Card", "Passed that on to its job.")]) === "Passed that on to its job." &&
      Told.toldLine([T("new", "x", "Handed that off to a background agent.", "On it.")]) === "On it." && Told.toldLine([]) === "")
    check("handoffs said: several, one line naming them by their titles' first words",
      Told.toldLine([T("land", "Fix the video card overlap", "Told its job to merge it."), T("land", "Dictation drops words after a pause", "x"), T("land", "Screenshots in the chat", "x")]) ===
        "Told three jobs, Fix the video card, Dictation drops words after and Screenshots in the chat, to merge." &&
      Told.toldLine([T("new", "Research Hexagon", "x"), T("follow", "Card fix", "x"), T("kept", "Notes", "Studio is offline: the job starts there once it's back.")]) ===
        "Handed off one job to background agents: Research Hexagon. Passed that on to Card fix. Studio is offline: the job starts there once it's back.", Told.toldLine([T("land", "Fix the video card overlap", "")]))
    const two = [T("new", "Research Hexagon", "Handed that off to a background agent."), T("new", "Card fix", "Handed that off to a background agent.")]
    check("handoffs said once a turn: its own words announced them, nothing more; else one line for both, never one each",
      Told.toldLine(two, "I've handed it off to a background agent to fix.") === "" && Told.toldLine([two[0]], "Two background agents are on it.") === "" && Told.toldLine(two, "I started two jobs, one each.") === "" &&
      Told.toldLine(two, "Sure.") === "Handed off two jobs to background agents: Research Hexagon and Card fix.", Told.toldLine(two))
    check("handoffs said once a turn: a say announcing it stands for every default line; one answering something else, and an offline machine, still said",
      Told.toldLine([T("new", "A", "x", "Handed that off, it runs on the mini PC."), T("new", "B", "x")]) === "Handed that off, it runs on the mini PC." &&
      Told.toldLine([T("new", "A", "x", "Handed that off."), T("new", "B", "x", "Passed that on to its job.")]) === "Handed that off." &&
      Told.toldLine([T("new", "A", "x", "You're on the personal account.")], "I've handed it off.") === "You're on the personal account." &&
      Told.toldLine([T("kept", "A", "Studio is offline: the job starts there once it's back.")], "Handed it off.") === "Studio is offline: the job starts there once it's back." &&
      !Told.announces("Sure, the header's blue now.") && !Told.announces("The footer job is ready for review.") && Told.announces("A background agent's on it.") &&
      Told.announces("I've passed that on to its job.") && Told.announces("Started two jobs for that.") && Told.announces("A job's on it."))
  }

  // Where: the addresses on screen, Tailscale Serve's ports, the rules, another machine's name.
  {
    const urls = W.urlsIn({ title: "Site", screen: "Address and search bar: localhost:5173/about\nhttps://github.com/lighthouse/site/pull/3" }).map((u) => u.href)
    check("where: the addresses an ask's screen shows", urls.join() === "http://localhost:5173/about,https://github.com/lighthouse/site/pull/3", urls)
    const status = { Web: { "box.tail1.ts.net:8450": { Handlers: { "/": { Proxy: "http://127.0.0.1:5173" } } }, "box.tail1.ts.net:443": { Handlers: { "/": { Proxy: "http://127.0.0.1:3000/" } } } } }
    check("where: a Tailscale Serve name's port is the local port it proxies", W.servedPort(status, "box.tail1.ts.net", "8450") === 5173 && W.servedPort(status, "box.tail1.ts.net", "") === 3000 &&
      W.servedPort(status, "box.tail1.ts.net", "9999") === 0)
    const home = "/Users/alice"
    check("where: a folder a rule names is refused with its why, others not", W.refusal("/Users/alice/Work/Acme/api", ["~/Work/Acme: Acme's work runs on its own machine"], home) === "Acme's work runs on its own machine" &&
      W.refusal("/Users/alice/Work/AcmeX", ["~/Work/Acme: no"], home) === "" && W.refusal("/Users/alice/Projects/site", ["~/Work/Acme"], home) === "")
    const P = await import("../../../plugins/core/companion/placement.ts")
    const mac = (id: string, o: Any = {}): Any => ({ id, label: id.toUpperCase(), online: true, self: false, standalone: false, platform: "darwin", vault: true, cores: 8, load: 1,
      memory: { total: 16384, free: 60 }, jobs: 0, cap: 4, repos: ["site", "lighthouse/site"], agents: ["claude", "codex"], accounts: ["default", "personal"], ...o })
    const ms = [mac("lap", { self: true }), mac("box", { standalone: true, vault: false, platform: "linux" }), mac("m1", { standalone: true }), mac("pc", { standalone: true, platform: "win32" })]
    const ids = (r: { ranked: { t: Any }[] }) => r.ranked.map((x) => x.t.id).join()
    const vaultJob = { has: ["vault" as const] }, coding = { has: [], repo: "lighthouse/site" }
    check("placement: auto is the always-on machines in their order, then this one; here first when it's always on; a list in its order, here closing it",
      P.orderOf("auto", ms).ids.join() === "box,m1,pc,lap" && P.orderOf("", ms).ids.join() === "box,m1,pc,lap" && P.orderOf("auto", ms.map((m) => (m.self ? { ...m, standalone: true } : m))).ids.join() === "lap,box,m1,pc" &&
      P.orderOf("pc, here", ms).ids.join() === "pc,lap" && P.orderOf(["M1", "nope"], ms).ids.join() === "m1,lap" && P.orderOf("m1,nope", ms).unknown.join() === "nope" && P.orderOf("here", ms).ids.join() === "lap")
    const plain = P.place(ms, vaultJob, "auto"), code = P.place(ms, coding, "auto")
    check("placement: a vault's job only where this vault is, a coding job on another vault's machine too; each left out says why",
      ids(plain) === "m1,pc,lap" && plain.left.includes("BOX has another vault") && ids(code) === "box,m1,pc,lap" && /^always on/.test(code.ranked[0].why), [plain, code])
    check("placement: a machine that's off is skipped, saying so; one that doesn't say what jobs it takes too",
      ids(P.place(ms.map((m) => (m.id === "m1" ? { ...m, online: false } : m)), vaultJob, "auto")) === "pc,lap" && P.place(ms.map((m) => (m.id === "m1" ? { ...m, online: false } : m)), vaultJob, "auto").left.includes("M1 is off") &&
      ids(P.place(ms.map((m) => (m.id === "box" ? { ...m, away: "doesn't say" } : m)), coding, "auto")) === "m1,pc,lap")
    check("placement: needs filter the machines (an OS, a desktop, the app, its repo, its agent and account)",
      ids(P.place(ms, { has: ["macos"] }, "auto")) === "m1,lap" && ids(P.place(ms, { has: ["linux"] }, "auto")) === "box" && P.place(ms, { has: ["linux"] }, "auto").left.includes("LAP runs macOS, not Linux") &&
      ids(P.place(ms.map((m) => (m.id === "m1" ? { ...m, display: false } : m)), { has: ["desktop"] }, "auto")) === "box,pc,lap" &&
      ids(P.place(ms.map((m) => (m.id === "m1" ? { ...m, repos: ["other"] } : m)), coding, "auto")) === "box,pc,lap" &&
      ids(P.place(ms.map((m) => (m.id === "box" ? { ...m, agents: ["claude"] } : m)), { has: [], agent: "codex" }, "auto")) === "m1,pc,lap" &&
      ids(P.place(ms.map((m) => (m.id === "pc" ? { ...m, accounts: ["default"] } : m)), { has: [], account: "personal" }, "auto")) === "box,m1,lap" &&
      ids(P.place(ms.map((m) => ({ ...m, repos: undefined, agents: undefined })), { has: [], repo: "x", agent: "y" }, "auto")) === "box,m1,pc,lap")
    const loaded = ms.map((m) => (m.id === "box" ? { ...m, load: 6 } : m.id === "m1" ? { ...m, jobs: 4 } : m))
    const busy = P.place(loaded, coding, "auto")
    check("placement: the most headroom first (a busy machine after a free one, a full one last), then the order; why says so",
      ids(busy) === "pc,lap,box,m1" && /^always on, the most headroom, load 0\.13 per core, 60% memory free, 0 of 4 jobs$/.test(busy.ranked[0].why) && /busy/.test(busy.ranked[2].why) &&
      /full/.test(busy.ranked[3].why) && ids(P.place(loaded, coding, "m1, box")) === "lap,box,m1", busy.ranked.map((x) => x.why))
    check("placement: a one-laptop setup runs everything here",
      ids(P.place([mac("lap", { self: true })], coding, "auto")) === "lap" && !P.place([mac("lap", { self: true })], coding, "auto").left.length)
    check("placement: headroom from load per core, free memory and jobs against its cap; unknown is room; a cap from cores and memory",
      P.headroom(mac("a")).level === "free" && P.headroom(mac("a", { memory: { total: 8192, free: 5 } })).level === "full" && P.headroom(mac("a", { load: 6 })).level === "busy" &&
      P.headroom({ id: "x", label: "X", self: false, online: true, standalone: false }).level === "free" && P.capOf(8, 16384) === 4 && P.capOf(2, 4096) === 1 && P.capOf(64, 262144) === 8)
    const rules = P.rulesIn(JSON.stringify({ needs: [{ when: "\\b(swift|helper|desktop app)\\b", needs: ["macos", "desktop"] }, { needs: ["nope"] }, { when: "(", needs: ["linux"] }, { needs: ["vault"] }] }))
    check("placement: a repo's rules (.vaultite-jobs.json) say what its work needs by its words; bad ones are left out",
      rules.length === 2 && P.rulesNeed(rules, "Fix the Swift helper's crash").join() === "macos,desktop,vault" && P.rulesNeed(rules, "Fix the sidebar").join() === "vault" &&
      P.rulesIn("not json").length === 0, rules)
    {
      const O = await import("../../../plugins/core/companion/jobos.ts")
      const onMac = { app: "app.vaultite.main", appName: "Vaultite Main", window: 42, text: "the traffic lights flicker when the window loses focus" }
      const mac = O.osNeed({ task: "Fix the flicker", about: "app" }, onMac), said = O.osNeed({ task: "Lights sit too low", os: "macos" }), phone = O.osNeed({ task: "Fix the tab bar", os: "ios" })
      const phoneWords = O.osNeed({ task: "The iPhone app's tab bar hides behind the keyboard", about: "app" })
      const idle = ms.map((m) => (m.id === "box" ? { ...m, load: 0, jobs: 0 } : m.id === "m1" ? { ...m, load: 6, jobs: 2 } : m))
      const linuxFirst = P.place(idle, { has: [], repo: "lighthouse/site" }, "auto"), macOnly = P.place(idle, { has: [mac!.need], repo: "lighthouse/site" }, "auto")
      check("placement: an ask about something one OS alone has (the Mac's window chrome, the iPhone app) runs on a Mac, however idle a Linux machine is; why says so",
        mac?.need === "macos" && /desktop app on a Mac, about its traffic lights/.test(mac.why) && said?.need === "macos" && phone?.need === "macos" && /iPhone app/.test(phone.why) &&
        phoneWords?.need === "macos" && /iPhone app/.test(phoneWords.why) &&
        O.osNeed({ task: "Fix the flicker", about: "app" }, { text: onMac.text }) === null && O.osNeed({ task: "Fix the flicker", about: "work" }, onMac) === null &&
        O.osNeed({ task: "The sidebar's width", about: "app" }, { ...onMac, text: "the sidebar is too wide" }) === null && O.osLine(mac!).endsWith(": on a Mac") &&
        linuxFirst.ranked[0].t.id === "box" && ids(macOnly) === "lap,m1" && macOnly.left.includes("BOX runs Linux, not macOS"), [mac, phone, phoneWords, ids(linuxFirst), ids(macOnly)])
    }
    {
      // The cloud: a session per job, no cap; after the always-on machines with room, before this one; only work needing nothing local.
      const cloud: Any = { id: "cloud", label: "Cloud", self: false, online: true, standalone: false, cloud: true, platform: "linux", vault: false, display: false, app: false, agents: ["claude"], accounts: ["personal"] }
      const all = [...ms, cloud], set = { has: [], repo: "lighthouse/site", cloud: true }
      check("placement: auto is the always-on machines, then the cloud, then this one; cloud names it in a list",
        P.orderOf("auto", all).ids.join() === "box,m1,pc,cloud,lap" && P.orderOf("cloud, m1", all).ids.join() === "cloud,m1,lap")
      const full = all.map((m) => (m.standalone ? { ...m, jobs: 4 } : m))
      check("placement: the cloud after the always-on machines with room, before this one and before a full one; why says it",
        ids(P.place(all, set, "auto")) === "box,m1,pc,cloud,lap" && ids(P.place(full, set, "auto")) === "cloud,lap,box,m1,pc" &&
        /^a cloud session of its own/.test(P.place(full, set, "auto").ranked[0].why) && ids(P.place(ms, coding, "auto")) === "box,m1,pc,lap", P.place(full, set, "auto").ranked.map((x) => x.why))
      const why = (n: Any) => P.lacks(cloud, n)
      check("placement: the cloud takes only work needing nothing of a machine, in a GitHub repo that says it runs there, in its account",
        why(set) === "" && why({ ...set, has: ["vault"] }) === "can't have this vault" && why({ ...set, has: ["macos", "desktop"] }) === "can't have macOS" &&
        why({ ...set, repo: "site" }) === "takes only a repo on GitHub" && /isn't set up for lighthouse\/site/.test(why({ ...set, cloud: false })) &&
        why({ ...set, account: "agent" }) === "has no account agent" && why({ ...set, agent: "codex" }) === "has no codex" && why({ ...set, has: ["linux"] }) === "" &&
        P.cloudIn('{"cloud": true}') && !P.cloudIn('{"needs": []}') && !P.cloudIn("nope"))
      const told = J.jobTask("Fix the footer", undefined, { cwd: "/r/site", repo: "site", base: "abc", label: "Cloud", cloud: true }, "j1", { land: true })
      check("jobs: a cloud job is told it has no vau nor vault, to ask through AskUserQuestion, to land from its branch and end Merged with its hash, never wait for live",
        /Fix the footer/.test(told) && /no vau/.test(told) && /AskUserQuestion/.test(told) && /from your session's branch[^]*git push origin HEAD:main[^]*Don't wait for it to go live[^]*"Merged:" and its commit's hash on main/.test(told) &&
        !/worktree|tour-save|vau inbox/.test(told) && !/git push/.test(J.jobTask("Fix it", undefined, { cwd: "/r/site", repo: "site", label: "Cloud", cloud: true }, "j1", { land: false }).replace(/don't push to main/, "")), told)
      check("jobs: a cloud job's card links its session on claude.ai", J.linkOf({ terminal: "session_01abc", where: where({ cloud: true, machine: "" }) }) === "view:web/https://claude.ai/code/session_01abc")
    }
    check("where: a preview or an editor's project is a copy the user watches here; a note, a GitHub page or nothing isn't",
      W.watched({ cwd: "/r", why: "", from: "preview" }) && W.watched({ cwd: "/r", why: "", from: "editor" }) && !W.watched({ cwd: "/r", why: "", from: "github" }) && !W.watched({ cwd: "/v", why: "", from: "vault" }))
    check("where: an address another machine serves goes to it", W.machineOfUrl({ url: "https://studio.tail1.ts.net:8450/x" }, { studio: "studio.tail1.ts.net" })?.machine === "studio" &&
      W.machineOfUrl({ url: "http://localhost:3000" }, { studio: "studio.tail1.ts.net" }) === null)
  }

  // Where on this machine: a GitHub page's checkout, a preview's process's repo, a note's vault.
  const { tmp, roots, repo, g, real, done } = jobSite()
  const { gitEnv } = await import("../../../core/gitenv.ts")
  {
    // A job's own change on main: a commit its words name, or its branch, after its base; nothing before it, nothing unpushed.
    const { onMainSince } = await import("../../../plugins/core/companion/jobgit.ts")
    const base = g("rev-parse", "HEAD").trim()
    fs.writeFileSync(path.join(repo, "a.txt"), "a\n"); g("add", "."); g("commit", "-qm", "landed"); const landed = g("rev-parse", "HEAD").trim()
    g("update-ref", "refs/remotes/origin/main", "HEAD")
    g("checkout", "-qb", "job-x"); fs.writeFileSync(path.join(repo, "b.txt"), "b\n"); g("add", "."); g("commit", "-qm", "unpushed"); const local = g("rev-parse", "--short", "HEAD").trim()
    const on = [await onMainSince(repo, base, `Pushed as ${landed}.`), await onMainSince(repo, base, `Committed as ${local}, not pushed.`), await onMainSince(repo, base, `Based on ${base.slice(0, 8)}.`),
      await onMainSince(repo, base, "Done.", "job-x"), await onMainSince(repo, landed, `Pushed as ${landed}.`)]
    check("jobs: a job's change is on main when a commit it names (or its branch) is on origin/main after its base", on.join() === "true,false,false,false,false", { landed, local, on })
    check("jobs: a commit its branch was rebased onto isn't its landing, though its words name it", !await onMainSince(repo, base, `Rebased onto ${landed.slice(0, 7)}, not pushed.`, "job-x"), landed)
    g("update-ref", "refs/remotes/origin/main", "job-x")
    check("jobs: its branch landed on main counts too", await onMainSince(repo, base, "Done.", "job-x"))
    g("checkout", "-q", "-"); g("branch", "-qD", "job-x"); g("update-ref", "-d", "refs/remotes/origin/main"); g("reset", "-q", "--hard", base)
  }
  {
    // Landed by someone else (rebased or squashed: a new sha), its branch removed: found by its change's patch-ids, read
    // while the branch existed; never another job's with the same words, nor main's commits a branch was rebased onto.
    const { onMainSince, marksOf } = await import("../../../plugins/core/companion/jobgit.ts")
    const base = g("rev-parse", "HEAD").trim(), on = g("symbolic-ref", "--short", "HEAD").trim(), put = (f: string, t: string, msg: string) => { fs.writeFileSync(path.join(repo, f), t); g("add", "."); g("commit", "-qm", msg) }
    g("update-ref", "refs/remotes/origin/main", base)
    g("checkout", "-qb", "job-y"); put("c.txt", "c\n", "feat: the header"); put("d.txt", "d\n", "feat: its footer")
    g("checkout", "-qb", "job-z", base); put("c.txt", "z\n", "feat: the header")
    g("checkout", "-q", "--detach", base); put("o.txt", "o\n", "chore: someone else's"); g("update-ref", "refs/remotes/origin/main", "HEAD")
    g("rebase", "-q", "origin/main", "job-z")
    const y = await marksOf(repo, "job-y"), z = await marksOf(repo, "job-z")
    check("jobs: a branch's marks are its own commits' patch-ids, not main's it was rebased onto; none on main yet",
      y?.each.length === 2 && !!y.whole && z?.each.length === 1 && !await onMainSince(repo, base, "Done.", "job-y", y) && !await onMainSince(repo, base, "Done.", "job-z", z), { y, z })
    g("checkout", "-q", "--detach", "origin/main"); g("merge", "-q", "--squash", "job-y"); g("commit", "-qm", "feat: header and footer"); g("update-ref", "refs/remotes/origin/main", "HEAD")
    g("branch", "-qD", "job-y")
    check("jobs: squashed onto main by someone else with its branch removed, a job's change is found by its marks; a rival's same words aren't",
      await marksOf(repo, "job-y") === null && await onMainSince(repo, base, "Done.", "job-y", y) && !await onMainSince(repo, base, "Done.", "job-z", z) &&
      !await onMainSince(repo, base, "Done.", "job-y", null) && !await onMainSince(repo, "origin/main", "Done.", "job-y", y), { y, z })
    const main = g("rev-parse", "HEAD").trim()
    g("checkout", "-qb", "job-w", base); put("w.txt", "w\n", "fix: one"); put("w.txt", "w\nx\n", "fix: two")
    g("checkout", "-q", "--detach", main); g("cherry-pick", "job-w~1", "job-w"); g("update-ref", "refs/remotes/origin/main", "HEAD")
    check("jobs: rebased onto main commit by commit, its branch still there, it's on main by its marks", await onMainSince(repo, base, "Done.", "job-w", await marksOf(repo, "job-w")))
    g("checkout", "-q", "-f", on); g("branch", "-qD", "job-z", "job-w"); g("update-ref", "-d", "refs/remotes/origin/main"); g("reset", "-q", "--hard", base)
  }
  await (async () => {
    const now = 100_000, w = (text: string, at: number, final: boolean) => J.turnWord({ text, at, final }, now)
    check("jobs: with no word from its terminal, a turn with a tool call open is working, its last words standing 30 s at rest, else unknown",
      w("", 0, false) === "working" && w("Checking.", now - 60_000, false) === "working" && w("Done.", now - 5000, true) === undefined &&
      w("Done.", now - 31_000, true) === "idle" && J.turnWord(null, now) === undefined && w("", 0, true) === undefined)
  })()
  await (async () => {
    const { diffSince } = await import("../../../plugins/core/companion/jobgit.ts")
    const base = g("rev-parse", "HEAD").trim(), on = g("symbolic-ref", "--short", "HEAD").trim(), put = (f: string, t: string, msg: string) => { fs.writeFileSync(path.join(repo, f), t); g("add", "."); g("commit", "-qm", msg) }
    put("m1.txt", "1\n2\n3\n", "chore: main moves on"); put("m2.txt", "x\n", "chore: and on"); g("update-ref", "refs/remotes/origin/main", "HEAD")
    const main = g("rev-parse", "HEAD").trim()
    g("checkout", "-qb", "job-v", main); put("v.txt", "v\n", "fix: the job's own")
    const rebased = await diffSince(repo, base), landed = await diffSince(repo, base, g("rev-parse", "--short", "HEAD").trim()), gone = await diffSince(repo, base, "", true)
    check("jobs: a rebased job's change count is against the main it's on now, a landed one's its commit's, none once its worktree is gone",
      rebased === "1 file changed, +1 -0, 1 commit" && landed === "1 file changed, +1 -0" && gone === "", { rebased, landed, gone })
    g("checkout", "-q", "-f", on); g("branch", "-qD", "job-v"); g("update-ref", "-d", "refs/remotes/origin/main"); g("reset", "-q", "--hard", base)
  })()
  {
    // A job's base: a checkout nothing pulls starts it from its branch's remote tip, fetched, its own files and branch untouched.
    const up = path.join(tmp, "up.git"), co = path.join(tmp, "lag"), other = path.join(tmp, "other")
    const gi = (cwd: string, ...a: string[]) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", ...a], { cwd, stdio: "pipe", env: gitEnv() }).toString().trim()
    gi(tmp, "init", "-q", "--bare", "-b", "main", up); gi(tmp, "clone", "-q", up, other)
    fs.writeFileSync(path.join(other, "a.txt"), "a\n"); gi(other, "add", "."); gi(other, "commit", "-qm", "first"); gi(other, "push", "-q", "origin", "HEAD:main")
    gi(tmp, "clone", "-q", up, co)
    const old = gi(co, "rev-parse", "HEAD")
    fs.writeFileSync(path.join(other, ".vaultite-jobs.json"), JSON.stringify({ needs: [{ needs: ["linux"] }] })); gi(other, "add", "."); gi(other, "commit", "-qm", "rules"); gi(other, "push", "-q", "origin", "HEAD:main")
    const tip = gi(other, "rev-parse", "HEAD")
    fs.writeFileSync(path.join(co, "a.txt"), "edited\n")
    const [st, b] = await api("POST", "ops/companion.where", { cwd: co })
    check("jobs: a checkout with nothing of its own starts a job at its branch's remote tip, fetched; its HEAD, branch and files as they were",
      st === 200 && b.base === tip && gi(co, "rev-parse", "HEAD") === old && gi(co, "rev-parse", "refs/heads/main") === old && fs.readFileSync(path.join(co, "a.txt"), "utf8") === "edited\n", [st, b, tip, old])
    check("jobs: a repo's rules are read from the commit a job starts at, not the checkout's files", b.rules?.[0]?.needs?.[0] === "linux" && !fs.existsSync(path.join(co, ".vaultite-jobs.json")), b.rules)
    gi(co, "checkout", "-q", "--", "a.txt"); gi(co, "merge", "-q", "--ff-only", "origin/main")
    fs.writeFileSync(path.join(co, "b.txt"), "b\n"); gi(co, "add", "."); gi(co, "commit", "-qm", "theirs")
    const mine = gi(co, "rev-parse", "HEAD")
    check("jobs: a checkout with commits of its own starts a job at its HEAD", await W.jobBase(co) === mine)
    gi(co, "reset", "-q", "--hard", tip)
    // A closed job's worktree: removed (its branch too, once on main) unless it has what exists nowhere else.
    const tree = (id: string) => { const t = path.join(tmp, `lag-${id}`); gi(co, "worktree", "add", "-q", t, "-b", `job-${id}`, tip); return t }
    const clean = tree("a"), dirty = tree("b"), ahead = tree("c")
    fs.writeFileSync(path.join(dirty, "new.txt"), "x\n")
    fs.writeFileSync(path.join(ahead, "c.txt"), "c\n"); gi(ahead, "add", "."); gi(ahead, "commit", "-qm", "unpushed")
    const why = [await W.dropTree(co, clean, "job-a"), await W.dropTree(co, dirty, "job-b"), await W.dropTree(co, ahead, "job-c")]
    const branches = gi(co, "branch", "--format=%(refname:short)").split("\n")
    check("jobs: a closed job's worktree is removed, and its branch once on main; one with changes or unpushed commits stays, saying why",
      why[0] === "" && !fs.existsSync(clean) && !branches.includes("job-a") && /uncommitted/.test(why[1]) && fs.existsSync(dirty) && /unpushed/.test(why[2]) && fs.existsSync(ahead) && branches.includes("job-c"), [why, branches])
    check("jobs: a worker told again after its worktree went is told how to make it again", /worktree add \S+lag-a job-a, or with that branch gone[^]*origin\/main/.test(J.prunedLine({ cwd: co, tree: clean, branch: "job-a" })))
  }
  {
    const gh = await W.resolveHere({ url: "https://github.com/lighthouse/site/issues/4" }, VAULT, [], roots)
    const note = await W.resolveHere({ path: "Notes/Plan.md", url: "http://localhost:1" }, VAULT, [], roots)
    check("where: a GitHub page is its checkout here; a note is the vault", fs.realpathSync(gh.cwd) === real && note.cwd === VAULT && gh.from === "github" && note.from === "note", [gh, note])
    const editor = await W.resolveHere({ app: "com.microsoft.VSCode", title: "index.html — site" }, VAULT, [], roots)
    check("where: an editor's window is its project's checkout", fs.realpathSync(editor.cwd) === real && editor.from === "editor", editor)
    // Each machine keeps its repos in its own place: another machine's path, a folder's name or GitHub's name is this one's own checkout.
    const named = (x: string) => { const d = W.checkoutNamed(x, roots); return d ? fs.realpathSync(d) : d }
    check("where: a repo another machine names (its path, its folder's name, GitHub's owner/name) is this machine's own checkout of it",
      named("/Users/alice/Projects/site") === real && named("~/Documents/personal/Projects/site") === real && named("site") === real && named("lighthouse/site") === real &&
      named("https://github.com/lighthouse/site.git") === real && named("~/Projects/elsewhere") === "" && named("lighthouse/nope") === "")
    W.checkoutsIn(roots)
    try {
      let [st, b] = await api("POST", "ops/companion.where", { cwd: "/Users/alice/Projects/site" })
      check("companion where: a folder another machine has its repo in finds this one's checkout, saying so", st === 200 && fs.realpathSync.native(b.cwd) === fs.realpathSync.native(repo) && b.repo === "site" &&
        /^\/Users\/alice\/Projects\/site is .*[\\/]site here$/.test(b.why), [st, b])
      ;[st, b] = await api("POST", "ops/companion.where", { repo: "lighthouse/site" })
      check("companion where --repo: by GitHub's name", st === 200 && fs.realpathSync.native(b.cwd) === fs.realpathSync.native(repo) && b.base.length === 40, [st, b])
      ;[st, b] = await api("POST", "ops/companion.where", { repo: "nowhere" })
      const [, text] = await api("POST", "ops/companion.where?as=text", { repo: "nowhere" })
      check("companion where: a repo with no checkout here says so, and where it looked: never a guess", st === 200 && b.missing === true &&
        new RegExp(`no checkout of nowhere \\(looked in ${roots[0].replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\)\\. Its checkouts: [^.]*[\\\\/]site`).test(String(text.text ?? text)) && /[\\/]site/.test(b.have), [b, text])
    } finally { W.checkoutsIn() }
    if (process.platform !== "win32") {
      const server = spawn(process.execPath, ["-e", "const s=require('http').createServer(()=>{}).listen(0,'127.0.0.1',()=>console.log(s.address().port))"], { cwd: path.join(repo), stdio: ["ignore", "pipe", "ignore"] })
      const port = await new Promise<string>((ok) => server.stdout!.once("data", (d) => ok(String(d).trim())))
      try {
        const pv = await W.resolveHere({ title: "Site", screen: `Address and search bar: localhost:${port}/about` }, VAULT, [], roots)
        check("where: a preview's address is the repo its server runs in", fs.realpathSync(pv.cwd) === real && pv.preview === `http://localhost:${port}`, pv)
      } finally { server.kill() }
    }
  }

  // A live site is the checkout whose deploy names its address, never a repo guessed from words on the page.
  {
    const { pageWins, namesRepo } = await import("../../../plugins/core/companion/jobplace.ts")
    const make = (name: string, slug: string, files: Record<string, string>) => {
      const dir = path.join(roots[0], name)
      for (const [f, t] of Object.entries(files)) { fs.mkdirSync(path.dirname(path.join(dir, f)), { recursive: true }); fs.writeFileSync(path.join(dir, f), t) }
      const gg = (...a: string[]) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", ...a], { cwd: dir, stdio: "pipe", env: gitEnv() }).toString()
      gg("init", "-q"); gg("remote", "add", "origin", `git@github.com:${slug}.git`); gg("add", "."); gg("commit", "-qm", "first")
      return { dir: fs.realpathSync(dir), gg }
    }
    // (the app names its website as its homepage; the site's wrangler deploys it; the API owns one path of it)
    const app = make("harbor", "lighthouse/harbor", { "package.json": JSON.stringify({ name: "harbor", homepage: "https://harbor.example" }) })
    const site = make("harbor-site", "lighthouse/harbor-site", { "wrangler.toml": '# harbor.example/api/* is harbor-api\'s route\nname = "harbor-site"\nroutes = [\n  { pattern = "harbor.example", custom_domain = true },\n]\n' })
    const api_ = make("harbor-api", "lighthouse/harbor-api", { "wrangler.jsonc": '{ "routes": [{ "pattern": "harbor.example/api/*", "zone_name": "harbor.example" }], "vars": { "ZONE": "harbor.example" } }' })
    const docs = make("beacon-docs", "lighthouse/beacon-docs", { "public/CNAME": "docs.beacon.example\n" })
    make("beacon-a", "lighthouse/beacon-a", { "CNAME": "beacon.example" }); make("beacon-b", "lighthouse/beacon-b", { "wrangler.toml": 'route = "beacon.example/*"' })
    site.gg("worktree", "add", "-q", path.join(roots[0], "harbor-site-j1"), "-b", "j1")
    W.checkoutsIn()
    const at = async (o: Any) => { const r = await W.resolveHere({ title: "Harbor - Private notes for you", ...o }, VAULT, [], roots); return { ...r, cwd: r.cwd === VAULT ? VAULT : fs.realpathSync(r.cwd) } }
    const home = await at({ url: "https://harbor.example/" }), www = await at({ url: "https://www.harbor.example/download" }), apiPage = await at({ url: "https://harbor.example/api/status" })
    check("where: a live site is the checkout its deploy config names (wrangler), not the app whose package.json names it its homepage, nor the site's worktree; www is its apex",
      home.cwd === site.dir && home.from === "site" && /harbor\.example is deployed from .*harbor-site \(its wrangler\.toml names harbor\.example\)/.test(home.why) && www.cwd === site.dir, [home, www])
    check("where: a path another repo's route claims is that repo's; a CNAME in public/ names its site", apiPage.cwd === api_.dir && (await at({ url: "https://docs.beacon.example/start" })).cwd === docs.dir, apiPage)
    const bar = await at({ app: "com.example.browser", screen: "Address and search bar: harbor.example/pricing\nRun it with localhost:1 locally" })
    check("where: a browser's address bar is the page's address, before a preview its text mentions", bar.cwd === site.dir, bar)
    const both = await at({ url: "https://beacon.example/" }), none = await at({ url: "https://nowhere.example/" }), title = await at({ app: "com.example.browser" })
    check("where: two repos deploying a site alike, or none, say so in why there and stay in the vault; a page's title alone names no repo",
      both.cwd === VAULT && /beacon\.example is deployed from .*beacon-a and .*beacon-b alike, so which is unclear: the vault/.test(both.why) &&
      none.cwd === VAULT && /no checkout here deploys nowhere\.example/.test(none.why) && title.cwd === VAULT && /nothing on screen named a project/.test(title.why), [both, none, title])
    const page = { cwd: site.dir, repo: "harbor-site", from: "site" as const }
    check("handoff: over a page with its own checkout, a repo the handoff named from its title is set aside; one their words name as a repo, or the same repo, stays",
      pageWins(page, "harbor", "try a serif font in the Harbor hero") && pageWins(page, "lighthouse/harbor", "make the harbor headline bigger") &&
      !pageWins(page, "harbor", "do it in the harbor repo instead") && !pageWins(page, "lighthouse/harbor", "port this to lighthouse/harbor") && !pageWins(page, "harbor-site", "x") &&
      !pageWins({ ...page, from: "vault" }, "harbor", "x") && namesRepo("in the repository harbor", "harbor") && !namesRepo("the harbor-site repo", "harbor"))
    fs.rmSync(site.dir, { recursive: true, force: true }); W.checkoutsIn()
    const orphan = await at({ url: "https://harbor.example/" })
    check("where: a worktree whose checkout was deleted deploys nothing, though its files name the site: the app naming it its homepage does",
      orphan.cwd === app.dir && /its package\.json names/.test(orphan.why) && !W.checkoutsLine(30, roots).includes("harbor-site-j1"), orphan)
    for (const d of ["harbor", "harbor-site-j1", "harbor-api", "beacon-docs", "beacon-a", "beacon-b"]) fs.rmSync(path.join(roots[0], d), { recursive: true, force: true })
    W.checkoutsIn()
  }

  // A worker's terminal ending mid-turn: closed on purpose (vau terminal end, End session) or exiting cleanly, it's done
  // by what it left, read from its session once the terminal's gone; crashed, it failed.
  if (process.platform !== "win32") {
    const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
    const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
    const plain = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-plain-")), ids: string[] = [], read: string[] = []
    let then = "sleep 600"
    cc["agent:claude"] = async () => ({ command: `sleep 0.3; printf '\\033]7501;state=working\\033\\\\'; sleep 1.5; ${then}`, cwd: null })
    cc["agent-turn:claude"] = async (_id: string, session = "") => { read.push(session); return { session: "sess-1", text: "Shipped it: committed and pushed.", files: [], at: Date.now(), final: false } }
    const job = async (id: string) => (await api("POST", "ops/companion.job", { id }))[1]
    const hand = async (how: string) => {
      then = how
      const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Ship it", say: "On it.", cwd: plain }, agent))
      if (st !== 200) return { st, b }
      ids.push(b.link.split("/").pop())
      await waitFor(async () => (await job(b.id)).state === "working", 10000, 100)
      return { st, b }
    }
    try {
      const clean = await hand("exit 0")
      const done = await waitFor(async () => { const r = await job(clean.b.id); return r.state !== "working" && r }, 15000, 200)
      check("jobs: a worker that exits mid-turn after its answer is done, its words read from its session after its terminal ended",
        done?.state === "done" && /Shipped it/.test(done.result?.text ?? "") && done.session === "sess-1" && read.includes("sess-1"), [done, read])
      check("jobs: an ended job's end is read once: it stays done", (await job(clean.b.id)).state === "done")
      const purpose = await hand("sleep 600")
      await api("DELETE", `terminals/${ids.at(-1)}`)
      const closed = await waitFor(async () => { const r = await job(purpose.b.id); return r.state !== "working" && r }, 15000, 200)
      check("jobs: a worker's terminal ended on purpose while it works, after it said something, is done", closed?.state === "done", closed)
      const crash = await hand("exit 3")
      const failed = await waitFor(async () => { const r = await job(crash.b.id); return r.state !== "working" && r }, 15000, 200)
      check("jobs: a worker that crashes mid-turn failed", failed?.state === "failed", failed)
    } finally {
      Object.assign(cc, was)
      for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
      for (const id of ids) await api("DELETE", `terminals/${id}`).catch(() => {})
      fs.rmSync(plain, { recursive: true, force: true })
    }
  }

  // A job done a while closes its terminal (not while its worker runs something in the background); its conversation
  // resumes with a follow-up.
  if (process.platform !== "win32") {
    const Wk = await import("../../../plugins/core/companion/workers.ts")
    const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
    const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
    const plain = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-tidy-")), started: Any[] = []
    const sleeping = { on: "sleep 600", since: Date.now(), n: 1 }
    let awaits: Any = sleeping
    cc["agent:claude"] = async (start: Any) => { started.push(start); return { command: "sleep 0.3; printf '\\033]7501;state=working\\033\\\\'; sleep 0.5; printf '\\033]7501;state=idle\\033\\\\'; sleep 600", cwd: null } }
    cc["agent-turn:claude"] = async () => ({ session: "sess-tidy", text: "Wrote the summary. Should I add it to Today?", files: [], at: Date.now(), final: true, awaits: awaits ?? undefined })
    const job = async (id: string) => (await api("POST", "ops/companion.job", { id }))[1]
    const runs = async (id: string) => (await api("GET", "terminals/sessions"))[1].sessions.some((x: Any) => x.id === id)
    let first = ""
    Wk.paced({ grace: 0 })
    try {
      const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Write the summary", cwd: plain }, agent))
      first = b.link.split("/").pop()
      const going = await waitFor(async () => { const r = await job(b.id); return r.state === "working" && r.now.startsWith("Waiting on sleep 600, since ") && r }, 15000, 200)
      check("jobs: its turn over while it runs something in the background, it stays working, saying it waits on that; its terminal stays",
        st === 200 && !!going && await runs(first) && !going.closed && !going.log.some((x: Any) => x.to === "done" || x.to === "ready for review"), going ?? await job(b.id))
      awaits = null
      const done = await waitFor(async () => { const r = await job(b.id); return r.state === "done" && r }, 25000, 200)
      check("jobs: its background tasks over and its turn after them ended, it's done", !!done, await job(b.id))
      const closed = await waitFor(async () => { const r = await job(b.id); return r.closed && r }, 10000, 200)
      check("jobs: done a while, its terminal closes by itself; it stays done, its result and questions kept, resuming from its card",
        !!closed && closed.state === "done" && closed.terminal === "resume-claude-sess-tidy" && /Wrote the summary/.test(closed.result?.text ?? "") &&
        closed.last?.asks?.[0] === "Should I add it to Today?" && !!(await waitFor(async () => !(await runs(first)), 5000, 100)), closed)
      const [st2, b2] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Yes, add it", job: b.id, title: "Summary on Today" }, agent))
      const resumed = started.at(-1)
      check("handoff --job on a closed job: its conversation resumed with the follow-up, renamed as asked",
        st2 === 200 && b2.state === "working" && b2.title === "Summary on Today" && b2.link === "view:terminal/resume-claude-sess-tidy" && resumed?.resume === "sess-tidy" &&
        resumed?.prompt === "Yes, add it" && !!(await waitFor(() => runs("resume-claude-sess-tidy"), 5000, 100)), [st2, b2, resumed])
    } finally {
      Wk.paced({ grace: L.PACE.grace })
      Object.assign(cc, was)
      for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
      for (const id of [first, "resume-claude-sess-tidy"]) if (id) await api("DELETE", `terminals/${id}`).catch(() => {})
      fs.rmSync(plain, { recursive: true, force: true })
    }
  }

  check("jobs: stuck only while its agent says it works and its program drew nothing for long, not after they said to keep waiting",
    !!L.stuckOf({ state: "working", now: "Reading a.jpg" }, {}, { running: true, state: "working", quiet: 30 * 60_000 }, 1e9, L.PACE)?.question.includes('nothing on its screen for 30 min after "Reading a.jpg"') &&
    !L.stuckOf({ state: "working", now: "" }, {}, { running: true, state: "working", quiet: 60_000 }, 1e9, L.PACE) &&
    !L.stuckOf({ state: "working", now: "" }, {}, { running: true, state: "idle", quiet: 3600_000 }, 1e9, L.PACE) &&
    !L.stuckOf({ state: "working", now: "" }, { kept: 1e9 - 60_000 }, { running: true, state: "working", quiet: 3600_000 }, 1e9, L.PACE) &&
    !L.stuckOf({ state: "ready for review", now: "" }, {}, { running: true, state: "working", quiet: 3600_000 }, 1e9, L.PACE))
  if (process.platform !== "win32") {
    const Wk = await import("../../../plugins/core/companion/workers.ts")
    const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
    const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
    const plain = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-stuck-")), started: Any[] = [], ids = new Set<string>()
    cc["agent:claude"] = async (start: Any) => { started.push(start); return { command: agentLine("stty -icanon -echo 2>/dev/null; sleep 0.3; printf '\\033]7501;state=working\\033\\\\'; IFS= read -r k; echo \"$k\" >> told.txt; printf '\\033]7501;state=working\\033\\\\'; sleep 600"), cwd: null } }
    cc["agent-turn:claude"] = async () => ({ session: "sess-stuck", text: "", files: [], at: Date.now() - 3600_000, final: false })
    const job = async (id: string) => (await api("POST", "ops/companion.job", { id }))[1]
    const stuckNow = (id: string) => waitFor(async () => { const r = await job(id); ids.add(r.terminal); return r.state === "needs you" && r.waits?.kind === "stuck" && r }, 15000, 200)
    Wk.paced({ stuck: 60_000 })
    try {
      const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Read the sheets", cwd: plain }, agent))
      await waitFor(async () => (await job(b.id)).state === "working", 10000, 100)
      const [sl, bl] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "They kept it: merge it", job: b.id, land: true }, agent))
      await waitFor(() => fs.existsSync(path.join(plain, "told.txt")), 5000, 100)
      Wk.paced({ stuck: 2500 })
      const stuck = await stuckNow(b.id)
      check("jobs: working yet drawing nothing for long, it needs them, saying it seems stuck, with a restart (its card's choices, its notification's buttons)",
        st === 200 && sl === 200 && !!stuck && stuck.waits.question.startsWith("It seems stuck: nothing on its screen for") && JSON.stringify(stuck.waits.choices) === '["Restart it","Keep waiting"]' &&
        stuck.now.startsWith("It seems stuck") && J.jobText(stuck).includes(`companion job-answer ${b.id} --choice "Restart it"`), [bl, stuck ?? await job(b.id)])
      const [s1, r1] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "go on", job: b.id }, agent))
      check("handoff --job to a job that seems stuck: refused, saying it can't reach its session and how to restart it, never \"Handed off\"",
        s1 === 409 && /seems stuck: nothing on its screen .*a follow-up can't reach its session: restart it first/.test(r1.error), [s1, r1])
      const [s2, r2] = await asItsTool(() => api("POST", "ops/companion.job-answer", { id: b.id, choice: "Keep waiting" }, agent))
      const kept = await job(b.id)
      check("job-answer Keep waiting: it works again, not asked again for a while", s2 === 200 && kept.state === "working" && !kept.waits, [s2, r2, kept])
      const [s3, r3] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "are you there?", job: b.id }, agent))
      check("handoff --job that its session drew nothing for once sent: refused, saying so (it seems stuck)",
        s3 === 409 && /drew nothing on its screen once it was sent/.test(r3.error), [s3, r3])
      const old = String((await stuckNow(b.id) || { terminal: "" }).terminal)
      const [s4, r4] = await asItsTool(() => api("POST", "ops/companion.job-answer", { id: b.id, choice: "Restart it" }, agent))
      const restarted = started.at(-1)
      ids.add("resume-claude-sess-stuck")
      check("job-answer Restart it: its terminal ended, its conversation resumed in a new one, told why",
        !!old && old !== "resume-claude-sess-stuck" && s4 === 200 && r4.answered === "Restart it" && restarted?.resume === "sess-stuck" && String(restarted?.prompt).startsWith("(Vaultite restarted this session: it seems stuck: nothing on its screen for") &&
        r4.link === "view:terminal/resume-claude-sess-stuck" && !!(await waitFor(async () => !(await api("GET", "terminals/sessions"))[1].sessions.some((x: Any) => x.id === old), 10000, 100)), [s4, r4, old, restarted?.prompt])
      await api("POST", "ops/companion.job-stop", { id: b.id }, agent)
      Wk.paced({ stuck: 60_000 })
      cc["agent-turn:claude"] = async () => ({ session: "sess-stuck2", text: "", files: [], at: Date.now() - 3600_000, final: false })
      const [, c] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Read more sheets", cwd: plain }, agent))
      await waitFor(async () => { const r = await job(c.id); ids.add(r.terminal); return r.state === "working" && r.session === "sess-stuck2" }, 10000, 100)
      const [sl2] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "They kept it: merge it", job: c.id, land: true }, agent))
      const merging = await job(c.id)
      const was = { state: merging.state, land: !!merging.land && merging.land.at === undefined }
      const [s5, r5] = await asItsTool(() => api("POST", "ops/companion.job-stop", { id: c.id }, agent))
      ids.add("resume-claude-sess-stuck2")
      check("job-stop by an agent of a job at work, told to merge: it follows its state (stopped, not refused as ready for review), its conversation kept to resume",
        sl2 === 200 && was.state === "working" && was.land && s5 === 200 && r5.state === "stopped" && r5.link === "view:terminal/resume-claude-sess-stuck2", [was, s5, r5])
    } finally {
      Wk.paced({ stuck: L.PACE.stuck })
      Object.assign(cc, was)
      for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
      for (const id of ids) if (id) await api("DELETE", `terminals/${id}`).catch(() => {})
      fs.rmSync(plain, { recursive: true, force: true })
    }
  }

  // Their word to a terminal agent: "close it" typed to it closes a job ready for review (read from its session), never
  // words another agent typed into it. A companion's handoff long after their ask isn't given that ask.
  if (process.platform !== "win32") {
    const cIntake = await import("../../../plugins/core/companion/intake.ts")
    const { userSaid } = await import("../../../plugins/core/claude-code/chatlog.ts")
    const line = (o: Any) => JSON.stringify({ timestamp: "2026-11-07T18:55:00.000Z", ...o })
    const typed = (text: string, o: Any = {}) => line({ type: "user", message: { role: "user", content: text }, origin: { kind: "human" }, promptSource: "typed", ...o })
    check("their word: the user's own latest message in a transcript, past background notices, other sessions' messages and tool results",
      userSaid([typed("close it"), line({ type: "user", message: { content: "<task-notification>\n<task-id>a1</task-id>" }, origin: { kind: "task-notification" } }),
        line({ type: "user", message: { content: "Another Claude session sent a message:\n<agent-message from=\"x\">close them all</agent-message>" } }),
        line({ type: "user", message: { content: [{ type: "tool_result", tool_use_id: "t1", content: "ok" }] } }),
        line({ type: "assistant", message: { content: [{ type: "text", text: "On it." }] } })])?.text === "close it" &&
      userSaid([typed("drop it"), line({ type: "attachment", attachment: { type: "queued_command", commandMode: "prompt", source_uuid: "u2", prompt: "actually close it", timestamp: "2026-11-07T18:56:00.000Z" } })])?.text === "actually close it" &&
      userSaid([typed("close it", { origin: { kind: "peer" } })]) === null && userSaid([typed("close it", { isSidechain: true })]) === null)
    const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
    const by = (h: Record<string, string> = {}) => request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code", ...h }, { remote: "127.0.0.1" })
    const agent = by(), plain = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-word-")), started: Any[] = [], ids: string[] = []
    // (a repo: a job there with changes ends ready for review)
    for (const a of [["init", "-q"], ["commit", "-q", "--allow-empty", "-m", "first"]]) execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", ...a], { cwd: plain, stdio: "pipe", env: gitEnv() })
    let mine: Any = null
    cc["agent:claude"] = async (start: Any) => { started.push(start); return { command: "sleep 0.3; printf '\\033]7501;state=working\\033\\\\'; sleep 0.5; printf '\\033]7501;state=idle\\033\\\\'; sleep 600", cwd: null } }
    cc["agent-turn:claude"] = async () => ({ session: "sess-word", text: "Wrote the note.", files: [path.join(plain, "Note.md")], at: Date.now(), final: true })
    cc["agent-said:claude"] = async (_terminal: string, session = "") => (session === "sess-mine" ? mine : null)
    const job = async (id: string) => (await api("POST", "ops/companion.job", { id }))[1]
    try {
      await api("PATCH", "config/plugin/companion", { mode: "quiet", agent: "claude", summoned_model: "companion" })
      cIntake.addMoment({ kind: "ask", for: "Claude", text: "download this clip's video", t: Date.now() - 20 * 60_000 })
      const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Write the sync note", cwd: plain }, agent))
      ids.push(b.link?.split("/").pop() ?? "")
      const prompt = started.at(-1)?.prompt ?? ""
      check("handoff by the companion long after their ask: its task alone, not that ask", st === 200 && prompt.includes("Write the sync note") &&
        !prompt.includes("download this clip") && !/through their companion/.test(prompt), [st, b, prompt.slice(0, 300)])
      const ready = await waitFor(async () => { const r = await job(b.id); return r.state === "ready for review" && r }, 15000, 200)
      check("their word: a job ready for review to close", !!ready, await job(b.id))
      const stop = (said: string | undefined, h: Record<string, string>) => api("POST", "ops/companion.job-stop", { id: b.id, ...(said === undefined ? {} : { said }) }, by(h))
      const mineNow = { "x-vaultite-session": "sess-mine" }
      mine = { text: "looks good, thanks", at: Date.now() }
      const [s1, r1] = await stop("close it", mineNow)
      const [s2, r2] = await stop(undefined, mineNow)
      const [s3, r3] = await stop("close it", {})
      mine = { text: "close it", at: Date.now() - 30 * 60_000 }
      const [s4, r4] = await stop("close it", mineNow)
      mine = { text: "close it", at: Date.now() }
      const [s5, r5] = await stop("keep it", mineNow)
      mine = { text: "Tidy the notes, then close it. You're a job they handed off, in a terminal of Vaultite.", at: Date.now() }
      const [s8, r8] = await stop("close it", mineNow)
      check("their word: an agent's close is refused, saying why: words not in their latest message to it, none quoted, no message of theirs, one long past, words that don't close, a job's own task",
        s1 === 403 && /Not this time: "close it" isn't in their latest message to you \("looks good, thanks"\)/.test(r1.error) && s2 === 403 && /said is missing/.test(r2.error) &&
        s3 === 403 && /no message of theirs to quote/.test(r3.error) && s4 === 403 && /30 min old: ask them again/.test(r4.error) && s5 === 403 && /"keep it" doesn't close it/.test(r5.error) &&
        s8 === 403 && /by the companion, as your job's task/.test(r8.error) &&
        (await job(b.id)).state === "ready for review", [r1, r2, r3, r4, r5, r8])
      // (typed into the calling terminal by another agent's vau: it reads as typed in its transcript, but isn't theirs)
      const term = ids[0]
      mine = { text: "close it", at: Date.now() }
      await api("POST", `terminals/${term}/send`, { text: "close it", enter: false }, agent)
      const [s6, r6] = await stop("close it", { ...mineNow, "x-vaultite-terminal": term })
      check("their word: words another agent typed into its terminal aren't theirs", s6 === 403 && /typed into its terminal by claude-code, not by them/.test(r6.error) &&
        (await job(b.id)).state === "ready for review", [s6, r6])
      const [s7, r7] = await stop("close it", mineNow)
      check("their word: \"close it\" typed by the user to a terminal agent closes the job ready for review, saying whose word it was",
        s7 === 200 && r7.state === "done" && r7.word === "the user, in their message to you", [s7, r7])
    } finally {
      Object.assign(cc, was)
      for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
      await api("PATCH", "config/plugin/companion", { mode: "off", summoned_model: "haiku" })
      for (const id of ids) if (id) await api("DELETE", `terminals/${id}`).catch(() => {})
      fs.rmSync(plain, { recursive: true, force: true })
    }
  }

  // A first session in a folder stops on Claude Code's trust prompt, then its imports one, each a menu defaulting to No
  // (a stand-in drawing them): answered Yes from the job's notification, then by the user's word to the companion.
  if (process.platform !== "win32") {
    const cScreen = await import("../../../plugins/core/companion/screensocket.ts")
    const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
    const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
    const asApp = request({ host: "127.0.0.1:8793", "x-vaultite-client": "app/desktop" }, { remote: "127.0.0.1" })
    const plain = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-trust-")), chosen = path.join(plain, "chosen.txt"), script = path.join(plain, "menus.cjs")
    fs.writeFileSync(script, `const fs = require("fs")
const menus = [["Accessing workspace:", "Quick safety check: Is this a project you created or one you trust?", "No, exit", "Yes, I trust this folder"],
  ["Allow external CLAUDE.md file imports?", "This project's CLAUDE.md imports files outside the current working directory.", "No, disable external imports", "Yes, allow external imports"]]
let m = 0, at = 0
const draw = () => { const [a, b, no, yes] = menus[m]; process.stdout.write("\\x1b[2J\\x1b[H" + [" " + a, "", " " + b, "", (at ? "   " : " ❯ ") + no, (at ? " ❯ " : "   ") + yes, "", " Enter to confirm · Esc to cancel"].join("\\r\\n")) }
process.stdin.setRawMode(true)
process.stdin.on("data", (d) => {
  const k = String(d)
  if (k === "\\x1b[B") at = 1; else if (k === "\\x1b[A") at = 0
  else if (k === "\\r") { fs.appendFileSync(${JSON.stringify(chosen)}, menus[m][2 + at] + "\\n"); m++; at = 0
    if (m === menus.length) { process.stdout.write("\\x1b[2J\\x1b[H\\x1b]7501;state=working\\x1b\\\\"); return } }
  draw()
})
setTimeout(draw, 300)
`)
    cc["agent:claude"] = async () => ({ command: `${JSON.stringify(process.execPath)} ${JSON.stringify(script)}; sleep 600`, cwd: null })
    cc["agent-turn:claude"] = async () => null
    const job = async (id: string) => (await api("POST", "ops/companion.job", { id }))[1]
    let id = ""
    try {
      await api("PATCH", "config/plugin/companion", { mode: "quiet", agent: "claude", summoned_model: "companion" })
      const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the site's header", cwd: plain }, agent))
      id = b.link?.split("/").pop() ?? ""
      const trust = await waitFor(async () => { const r = await job(b.id); return r.state === "needs you" && r.waits && r }, 15000, 200)
      check("jobs: a worker stopped on its folder's trust prompt needs you, with the prompt's question and its choices (Yes first)", st === 200 && !!trust &&
        /^Trust this folder\?/.test(trust.waits.question) && trust.waits.choices.join() === "Yes, I trust this folder,No, exit" && trust.waits.kind === "permission", trust)
      const [, list] = await api("POST", "ops/companion.jobs", {})
      check("jobs: its card carries what it waits on, for its notification's buttons", list.jobs[0]?.waits?.choices?.[0] === "Yes, I trust this folder", list.jobs[0]?.waits)
      let [s2, r2] = await asItsTool(() => api("POST", "ops/companion.job-answer", { id: b.id, choice: "yes", said: "yes" }, agent))
      check("job-answer: an agent can't answer it without the user's words in an ask after it began waiting", s2 === 403, [s2, r2])
      ;[s2, r2] = await api("POST", "ops/companion.job-answer", { id: b.id, choice: "Yes, I trust this folder" }, asApp)
      const first = await waitFor(() => fs.existsSync(chosen) && fs.readFileSync(chosen, "utf8"), 5000, 50)
      check("job-answer from its notification: Yes chosen in its terminal, the cursor moved off the default No first", s2 === 200 && r2.answered === "Yes, I trust this folder" &&
        first === "Yes, I trust this folder\n", [s2, r2, first])
      const imports = await waitFor(async () => { const r = await job(b.id); return r.state === "needs you" && /imports/.test(r.waits?.question ?? "") && r }, 15000, 200)
      check("jobs: its imports prompt next is what it waits on now", !!imports && imports.waits.choices[0] === "Yes, allow external imports", imports)
      cScreen.screenMoment({ kind: "ask", agent: "Claude", text: "Yes, allow them. Thanks", voice: true, app: "com.example.browser", title: "Site", sx: 10, sy: 20 })
      ;[s2, r2] = await asItsTool(() => api("POST", "ops/companion.job-answer", { id: b.id, choice: "no", said: "no" }, agent))
      check("job-answer: words the user didn't say aren't theirs", s2 === 403 && !fs.readFileSync(chosen, "utf8").includes("disable"), [s2, r2])
      const [, jobsNow] = await api("POST", "ops/companion.job", { id: b.id })
      ;[s2, r2] = await asItsTool(() => api("POST", "ops/companion.job-answer", { id: b.id, choice: "yes", said: "yes, allow them" }, agent))
      const both = await waitFor(() => { const t = fs.readFileSync(chosen, "utf8"); return t.split("\n").length > 2 && t }, 5000, 50)
      check("job-answer by voice: the companion answers with the user's word in their ask, its choice pressed in the terminal", s2 === 200 && r2.answered === "Yes, allow external imports" &&
        both === "Yes, I trust this folder\nYes, allow external imports\n", [s2, r2, both, jobsNow.waits])
      const on = await waitFor(async () => { const r = await job(b.id); return r.state === "working" && r }, 10000, 200)
      check("jobs: answered, it works on, waiting on nothing", !!on && !on.waits, on)
    } finally {
      Object.assign(cc, was)
      for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
      await api("POST", "ops/companion.next", { timeout: 0 })
      await api("PATCH", "config/plugin/companion", { mode: "off", summoned_model: "haiku" })
      if (id) await api("DELETE", `terminals/${id}`).catch(() => {})
      fs.rmSync(plain, { recursive: true, force: true })
    }
  }

  // A picture another machine's companion hands on for a job here: kept out of the vault, by the helper's name only.
  {
    const { Readable } = await import("node:stream")
    const take = (name: string, bytes: Buffer) => app.runOp("companion.picture-take", { name }, { input: Readable.from([bytes]) }).then((r): Any => r.result, (e: Error) => e.message)
    const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(500, 1)])
    const got = await take("close-3-44.png", png), bad = await take("../x.png", png), notPng = await take("display-1-2.png", Buffer.from("hello"))
    check("picture-take: a picture handed on is kept on this machine, out of the vault, and its path answered; a name not the helper's, or not a PNG, refused",
      typeof got?.path === "string" && got.path.endsWith(path.join("screens", "close-3-44.png")) && !got.path.startsWith(VAULT) && fs.readFileSync(got.path).equals(png) &&
      /isn't a picture of the screen's name/.test(bad) && /isn't a PNG/.test(notPng), [got, bad, notPng])
  }

  // A job's worker on another machine reports home: vau sends what reaches the user there, a proof's files and its save too.
  {
    const http = await import("node:http")
    const got: Any[] = []
    const home = http.createServer((req, res) => {
      const chunks: Buffer[] = []
      req.on("data", (d) => chunks.push(d))
      req.on("end", () => {
        const [route, qs] = req.url!.split("?"), raw = Buffer.concat(chunks), q = Object.fromEntries(new URLSearchParams(qs))
        const file = route.endsWith("/companion.job-file")
        got.push({ route, q, terminal: req.headers["x-vaultite-terminal"], client: req.headers["x-vaultite-client"], ...(file ? { bytes: raw.length } : { p: raw.length ? JSON.parse(String(raw)) : {} }) })
        const out = file ? { path: `/home/alice/job-files/${q.job}/${q.name}` } : route.endsWith("/companion.tour-save") ? { path: "Guides/Proofs/The blue button.md", steps: 1, job: "jabc123" } : "Knocked."
        res.writeHead(200, { "Content-Type": typeof out === "string" ? "text/plain" : "application/json" }).end(typeof out === "string" ? out : JSON.stringify(out))
      })
    }).listen(0, "127.0.0.1")
    await new Promise((r) => home.once("listening", r))
    const url = `http://127.0.0.1:${portOf(home)}`
    try {
      const { execute, cliApi } = $.vars, { homeEnv } = await import("../../../core/cli.ts")
      const env = { VAULTITE_HOME: url, VAULTITE_HOME_AS: "box", VAULTITE_TERMINAL: "claude-abc", CLAUDECODE: "1" }
      const r = await execute(["companion", "knock", "Ready to look"], { api: cliApi, env, stdin: async () => "" })
      const k = got.find((x) => x.route === "/api/ops/companion.knock")
      check("vau from a job's worker on another machine: what reaches the user goes to its home, its terminal named as home knows it",
        r.code === 0 && r.out === "Knocked." && k?.p.line === "Ready to look" && k.p.terminal === "claude-abc@box" && k.terminal === "claude-abc@box", [r, got])
      const n = got.length, local = await execute(["companion", "jobs"], { api: cliApi, env, stdin: async () => "" })
      check("vau from a job's worker: the rest stays with its own server; the same server, or no home, is its own",
        local.code === 0 && got.length === n && homeEnv({ ...env, VAULTITE_URL: url }, { home: true }) === null && homeEnv({}, { home: true }) === null && homeEnv(env, {}) === null, [local, got.slice(n)])
      const dir = fs.mkdtempSync(path.join(os.tmpdir(), "proof-")), video = path.join(dir, "demo.mp4"), before = path.join(dir, "before.png")
      fs.writeFileSync(video, Buffer.alloc(2048, 1)); fs.writeFileSync(before, Buffer.alloc(300, 2))
      try {
        got.length = 0
        const saved = await app.runOp("companion.tour-save", { title: "The blue button", job: "jabc123", home: url, video, times: [0, 1500], open: "Notes/Idea.md",
          text: `1. Save is blue now [ring "Save"]. (before: ${before})` }).then((x): Any => x.result, (e: Error) => e.message)
        const files = got.filter((x) => x.route === "/api/ops/companion.job-file"), save = got.find((x) => x.route === "/api/ops/companion.tour-save")
        check("tour-save --job from a worker away from home: its video and pictures sent there, then saved there naming their paths there, nothing in this vault",
          saved?.path === "Guides/Proofs/The blue button.md" && saved.home === url && files.map((x) => `${x.q.name}:${x.bytes}`).sort().join() === "The blue button.mp4:2048,before 1.png:300" &&
          save?.p.video === "/home/alice/job-files/jabc123/The blue button.mp4" && JSON.stringify(save.p.times) === "[0,1500]" && save.p.text.includes("(before: /home/alice/job-files/jabc123/before 1.png)") &&
          save.p.job === "jabc123" && save.p.open === "Notes/Idea.md" && files.every((x) => x.client?.startsWith("machine/")) && !fs.existsSync(path.join(VAULT, "Guides", "Proofs", "The blue button.md")), [save?.p, files.length])
      } finally { fs.rmSync(dir, { recursive: true, force: true }) }
      const cap: Any = (await app.runOp("companion.capacity", {})).result
      check("companion.capacity: the jobs this machine runs, how many it takes, its agents and checkouts", typeof cap.jobs === "number" && cap.cap >= 1 && cap.agents.includes("claude") && Array.isArray(cap.repos), cap)
      if (process.platform !== "win32") {
        const t: Any = (await app.runOp("terminal.start", { command: `${JSON.stringify(process.execPath)} -e "console.log('home=' + process.env.VAULTITE_HOME + ' as=' + process.env.VAULTITE_HOME_AS)"`, wait: true, timeout: 30,
          home: { url, as: "box" } })).result
        check("terminal.start --home: its programs get the job's home server and this machine's id there", t.output?.includes(`home=${url} as=box`), t)
        const { asFromDock } = await import("../../../core/sessionenv.ts")
        const said = await app.runOp("terminal.start", { command: `${JSON.stringify(process.execPath)} -e "console.log('names=' + Object.keys(process.env).join(' '))"`, wait: true, timeout: 30, home: { url, as: "box" } })
        const { z } = await import("zod")
        const env = Object.fromEntries((/names=([^\r\n]*)/.exec(z.object({ output: z.string() }).parse(said.result).output)?.[1] ?? "").split(" ").filter(Boolean).map((k) => [k, "1"]))
        asFromDock(env)
        const left = Object.keys(env).filter((k) => k.startsWith("VAULTITE") && !/^VAULTITE_TEST(_RUN|_HOME|_TMPDIR)?$/.test(k))
        check("a test run in a job's terminal drops every variable that terminal sets (core/sessionenv.ts)", "PATH" in env && left.length === 0, left)
        const bad = await app.runOp("terminal.start", { command: "true", home: { url: "https://evil.example.com", as: "box" } }).then(() => "", (e: Error) => e.message)
        check("terminal.start --home: only a server on the tailnet", /home: \{url, as\}/.test(bad), bad)
      }
    } finally { home.close() }
  }

  done()
}
