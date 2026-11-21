import { check } from "../lib.ts"

// ---------- Browser: who's signed in to a site (electron/siteaccounts.ts), on made-up answers ----------
const sa = await import("../../../electron/siteaccounts.ts")
const read = (site: string, body: unknown, cookies: Record<string, string> = {}, url = "") => sa.ACCOUNTS[site].read!(body, async (_d, name) => cookies[name] ?? "", url)
const name = async (...a: Parameters<typeof read>) => { const v = await read(...a); return (typeof v === "string" ? v : v?.account) || null } // (as electron/webaccounts.ts askWho: "" names nobody)
const look = (site: string, v: unknown) => sa.ACCOUNTS[site].look!.read(v)
const list = '["gaia.l.a.r",[["gaia.l.a",1,"Alice Park","alice.park@example.com","https://lh3.example.com/a.png",1,1,0,null,1,"1001",null,null,null,0,1],' +
  '["gaia.l.a",1,"Lighthouse","studio@example.com","",1,1,0,null,1,"1002",null,null,null,0,1],["gaia.l.a",1,"Old","old@example.com","",1,1,0,null,1,"1003",null,null,null,1,1]]]'
check("accounts: Google's list, the first signed in, the others beside it, a signed-out one left out",
  JSON.stringify(sa.googleAccounts(list)) === JSON.stringify({ account: "alice.park@example.com", more: ["studio@example.com"], avatar: "https://lh3.example.com/a.png" }), sa.googleAccounts(list))
const wrapped = `<html><body><script>window.parent.postMessage('${list.replace(/"/g, "\\x22")}', 'https://accounts.google.com')</script></body></html>`
check("accounts: Google's list inside the page it sometimes answers", sa.googleAccounts(wrapped)?.account === "alice.park@example.com", sa.googleAccounts(wrapped))
check("accounts: Google, nobody signed in", sa.googleAccounts('["gaia.l.a.r",[]]') === null && sa.googleAccounts("<html>Sign in</html>") === null)
check("accounts: Reddit's name, its picture's address unescaped",
  JSON.stringify(await read("reddit.com", { data: { name: "alice_park", icon_img: "https://styles.example.com/a.png?s=1&amp;b=2" } })) === JSON.stringify({ account: "u/alice_park", avatar: "https://styles.example.com/a.png?s=1&b=2" }))
check("accounts: GitHub's login from its page, none signed out",
  (await read("github.com", '<meta name="user-login" content="alicepark">') as { account: string })?.account === "alicepark" && await read("github.com", '<meta name="user-login" content="">') === null)
const x = '{"users":{"7":{"id_str":"7","screen_name":"someone"},"42":{"id_str":"42","name":"Alice","screen_name":"alicepark","profile_image_url_https":"https:\\/\\/pbs.example.com\\/a.jpg"}}}'
const xWho = await read("x.com", x, { twid: "u%3D42" }) as { account: string; avatar: string } | null
check("accounts: X, the user whose id the twid cookie has, not another on the page", xWho?.account === "@alicepark" && xWho.avatar === "https://pbs.example.com/a.jpg", xWho)
check("accounts: X, no twid cookie: nobody", await read("x.com", x) === null)
check("accounts: claude.ai's email", await read("claude.ai", { account: { email_address: "alice@example.com" } }) === "alice@example.com")
check("accounts: X's handle and picture from an open page's sidebar, nothing from a page without it",
  JSON.stringify(sa.xLooked({ handle: "alicepark", avatar: "https://pbs.example.com/a.jpg" })) === JSON.stringify({ account: "@alicepark", avatar: "https://pbs.example.com/a.jpg" }) && sa.xLooked(null) === null && sa.xLooked({ handle: "i/flow/login" }) === null)
check("accounts: Hacker News's name from its login cookie, none without one",
  await read("ycombinator.com", null, { user: "alicepark&k3yH4sh" }) === "alicepark" && await read("ycombinator.com", null) === null)
check("accounts: Instagram's handle, none signed out", await name("instagram.com", { form_data: { username: "alice.park" } }) === "@alice.park" && await name("instagram.com", { message: "login_required" }) === null)
const fb = '<script>{"define":[["CurrentUserInitialData",[],{"ACCOUNT_ID":"4242","USER_ID":"4242","NAME":"Alice Park \\u00c9","SHORT_NAME":"Alice"},270]]}</script>'
check("accounts: Facebook's name for the user its c_user cookie has, none for another or without it",
  await name("facebook.com", fb, { c_user: "4242" }) === "Alice Park \u00c9" && await name("facebook.com", fb, { c_user: "7" }) === null && await name("facebook.com", fb) === null)
check("accounts: LinkedIn's handle from the profile /in/me/ took it to, none when it stayed",
  await name("linkedin.com", "", {}, "https://www.linkedin.com/in/alice-park-1a2b/") === "alice-park-1a2b" && await name("linkedin.com", "", {}, "https://www.linkedin.com/in/me/") === null &&
  await name("linkedin.com", "", {}, "https://www.linkedin.com/login") === null)
check("accounts: Cloudflare's, Cursor's, Apple's and GitLab's emails or names from their own answers",
  await name("cloudflare.com", { success: true, result: { email: "alice@example.com" } }) === "alice@example.com" && await name("cloudflare.com", { success: false, result: null }) === null &&
  await name("cursor.com", { email: "alice@example.com", name: "Alice" }) === "alice@example.com" && await name("apple.com", { user: { fullName: "Alice Park", emailAddress: "alice@example.com" } }) === "alice@example.com" &&
  await name("gitlab.com", { id: 1, username: "alicepark" }) === "alicepark" && await name("gitlab.com", { message: "401 Unauthorized" }) === null)
check("accounts: Wikipedia's user, none for an IP address signed out",
  await name("wikipedia.org", { query: { userinfo: { id: 12, name: "Alice Park" } } }) === "Alice Park" && await name("wikipedia.org", { query: { userinfo: { id: 0, name: "192.0.2.1", anon: "" } } }) === null)
check("accounts: Perplexity's email", await name("perplexity.ai", { user: { email: "alice@example.com" } }) === "alice@example.com" && await name("perplexity.ai", {}) === null)
check("accounts: Slack's email from its workspace's settings page, none at its sign-in page",
  await name("slack.com", '<h2>Email Address</h2><p class="no_bottom_margin">Your email address is <strong>alice@example.com</strong></p>') === "alice@example.com" &&
  await name("slack.com", "<html><title>Sign in to Slack | Slack</title></html>") === null)
check("accounts: WhatsApp's number off its open app, signed in unnamed without it, out at its QR code",
  JSON.stringify(look("whatsapp.com", { phone: '"5511987654321:12@c.us"' })) === '{"account":"+5511987654321"}' && JSON.stringify(look("whatsapp.com", { phone: "" })) === '{"account":""}' &&
  look("whatsapp.com", { out: true }) === false && sa.phoneOf("12@c.us") === "")
check("accounts: a rule's answer at a dotted path, only a string", sa.at({ a: { b: " x " } }, "a.b") === "x" && sa.at({ a: { b: 3 } }, "a.b") === "" && sa.at(null, "a.b") === "")
check("accounts: Google's login covers YouTube and google.<country>, not other sites",
  sa.covers("youtube.com", "youtube.com") && sa.covers("google.*", "google.com.br") && sa.covers("google.*", "google.co.uk") && !sa.covers("google.*", "google.com") && !sa.covers("google.*", "googleapis.com") && !sa.covers("youtube.com", "youtu.be"))
const google = sa.ACCOUNTS["google.com"].with!
check("accounts: Google's login covers YouTube by any login cookie YouTube keeps for it, not by a visitor's",
  ["SID", "__Secure-3PSID", "LOGIN_INFO"].every((n) => google["youtube.com"].test(n)) && !["VISITOR_INFO1_LIVE", "PREF", "SIDCC", "__Secure-3PSIDTS"].some((n) => google["youtube.com"].test(n)))
const signed = (site: string, n: string) => sa.ACCOUNTS[site].signed!.test(n)
check("accounts: a login cookie says signed in by its whole name, a cookie that only starts the same doesn't",
  signed("slack.com", "d") && !signed("slack.com", "dd_s") && signed("google.com", "SID") && !signed("google.com", "SIDCC") &&
  signed("ycombinator.com", "user") && !signed("ycombinator.com", "user-data") && signed("claude.ai", "sessionKey") && signed("amazon.com", "at-main") && !signed("amazon.com", "session-id") &&
  signed("stripe.com", "__Host-session") && !signed("stripe.com", "__Host-sandbox_assignment") && signed("notion.so", "token_v2") && signed("spotify.com", "sp_dc") && !signed("spotify.com", "sp_t"))
check("accounts: Amazon's name from its greeting, none at its sign-in greeting",
  await name("amazon.com", '<span id="nav-link-accountList-nav-line-1" class="nav-line-1 nav-progressive-content">Hello, Alice</span>') === "Alice" &&
  await name("amazon.com", '<span id="nav-link-accountList-nav-line-1" class="nav-line-1">Hello, sign in</span>') === null && await name("amazon.com", "<html>Robot check</html>") === null)
const ph = (viewer: string) => `<script>{"data":{"viewer":{"__typename":"Viewer",${viewer}}}}</script>`
check("accounts: Product Hunt's username from the viewer its page carries, its email without one, none signed out",
  await name("producthunt.com", ph('"email":"alice@example.com","isLoggedIn":true,"user":{"__typename":"User","id":"7","name":"Alice","username":"alicepark"}')) === "@alicepark" &&
  await name("producthunt.com", ph('"email":"alice@example.com","isLoggedIn":true,"user":null')) === "alice@example.com" &&
  await name("producthunt.com", ph('"email":null,"isLoggedIn":false,"user":null')) === null && await name("producthunt.com", "<html>Just a moment...</html>") === null)
check("accounts: Substack's handle, its name without one, none when it asks to sign in",
  JSON.stringify(await read("substack.com", { id: 1, name: "Alice Park", handle: "alicepark", photo_url: "https://substack.example.com/a.png" })) === JSON.stringify({ account: "@alicepark", avatar: "https://substack.example.com/a.png" }) &&
  await name("substack.com", { name: "Alice Park" }) === "Alice Park" && await name("substack.com", { errors: [{ msg: "Please sign in" }] }) === null)
check("accounts: TikTok's username, none signed out", await name("tiktok.com", { data: { username: "alice.park", screen_name: "Alice" }, message: "success" }) === "@alice.park" &&
  await name("tiktok.com", { data: { error_code: 1 }, message: "error" }) === null)
check("accounts: Twitch's name from its own cookie, none without it",
  await name("twitch.tv", null, { login: "alicepark" }) === "alicepark" && await name("twitch.tv", null) === null && await name("twitch.tv", null, { login: "a b" }) === null)
check("accounts: Grok's login covers x.ai, its company's site", sa.covers("x.ai", "x.ai") && sa.ACCOUNTS["grok.com"].with!["x.ai"].test("sso") && !sa.ACCOUNTS["grok.com"].with!["x.ai"].test("sso-rw"))
