import { execFileSync } from "node:child_process"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { gitEnv } from "../../../core/gitenv.ts"

export function jobSite() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-")), roots = [path.join(tmp, "Projects")], repo = path.join(roots[0], "site")
  fs.mkdirSync(repo, { recursive: true })
  const g = (...a: string[]) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", ...a], { cwd: repo, stdio: "pipe", env: gitEnv() }).toString()
  g("init", "-q"); g("remote", "add", "origin", "git@github.com:lighthouse/site.git"); fs.writeFileSync(path.join(repo, "index.html"), "<h1>Hi</h1>\n"); g("add", "."); g("commit", "-qm", "first")
  return { tmp, roots, repo, g, real: fs.realpathSync(repo), done: () => fs.rmSync(tmp, { recursive: true, force: true }) }
}
