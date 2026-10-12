// Runs services/scripts/integrations.js (a QML .pragma library) under node: node scripts/test_integrations.mjs
import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const src = readFileSync(new URL("../services/scripts/integrations.js", import.meta.url), "utf8").replace(/^\.pragma library\n/, "");
const P = new Function(`${src}; return { github, vercel, resend, notion, n8n, ago, safeUrl };`)();
const now = Date.parse("2026-01-01T12:00:00Z");

// GitHub: failing main CI first, then review requests, then my PRs; unsafe urls dropped
const gh = P.github({ data: {
  viewer: {
    pullRequests: { nodes: [
      { number: 42, title: "Fix it", url: "https://github.com/a/b/pull/42", isDraft: false, reviewDecision: "APPROVED",
        repository: { nameWithOwner: "a/b" }, commits: { nodes: [{ commit: { statusCheckRollup: { state: "SUCCESS" } } }] } },
      { number: 43, title: "WIP", url: "javascript:alert(1)", isDraft: true, reviewDecision: null,
        repository: { nameWithOwner: "a/b" }, commits: { nodes: [{ commit: { statusCheckRollup: null } }] } },
    ] },
    repositories: { nodes: [
      { nameWithOwner: "a/b", url: "https://github.com/a/b", isArchived: false,
        defaultBranchRef: { name: "main", target: { statusCheckRollup: { state: "FAILURE" } } } },
      { nameWithOwner: "a/old", url: "https://github.com/a/old", isArchived: true,
        defaultBranchRef: { name: "main", target: { statusCheckRollup: { state: "FAILURE" } } } },
    ] },
  },
  reviewRequested: { issueCount: 3, nodes: [{ number: 7, title: "Review me", url: "https://github.com/c/d/pull/7", author: { login: "bob" }, repository: { nameWithOwner: "c/d" } }] },
} });
assert.equal(gh.headline, "2 PRs · 3 to review · 1 CI failing");
assert.deepEqual(gh.rows.map(r => r.dot), ["#F4505E", "#8AB4F8", "#22C55E", "#6B7079"]);
assert.equal(gh.rows[0].url, "https://github.com/a/b/actions");
assert.equal(gh.rows[1].sub, "review requested · @bob");
assert.equal(gh.rows[2].sub, "approved");
assert.equal(gh.rows[3].url, "", "non-https url dropped");
assert.equal(gh.rows[3].sub, "draft");
assert.equal(P.github({}), null);

// Vercel: only finished deployments
const v = P.vercel({ deployments: [
  { name: "site", state: "BUILDING", createdAt: now },
  { name: "site", state: "READY", url: "site.vercel.app", createdAt: now - 3 * 60000, meta: { githubCommitRef: "main", githubCommitMessage: "ship" } },
  { name: "api", state: "ERROR", createdAt: now - 7200000 },
] }, now);
assert.equal(v.rows.length, 2);
assert.deepEqual([v.rows[0].dot, v.rows[0].right, v.rows[0].sub, v.rows[0].url], ["#22C55E", "3m", "main · ship", "https://site.vercel.app"]);
assert.deepEqual([v.rows[1].dot, v.rows[1].right], ["#F4505E", "2h"]);

// Resend
const r = P.resend({ total: 9, data: [{ to: ["ann@x.com"], subject: "Hi", last_event: "bounced", created_at: "2026-01-01T11:00:00Z" }] }, now);
assert.deepEqual([r.headline, r.rows[0].title, r.rows[0].dot, r.rows[0].right], ["9", "ann", "#F4505E", "1h"]);

// Notion: page title from properties, emoji icon, database title
const n = P.notion({ results: [
  { object: "page", icon: { type: "emoji", emoji: "📝" }, url: "https://notion.so/p", last_edited_time: "2026-01-01T11:59:00Z",
    properties: { Name: { type: "title", title: [{ plain_text: "Plan" }] } } },
  { object: "database", title: [], url: "http://evil", last_edited_time: "2025-12-30T12:00:00Z" },
] }, now);
assert.deepEqual([n.rows[0].title, n.rows[0].right, n.rows[0].url], ["📝 Plan", "1m", "https://notion.so/p"]);
assert.deepEqual([n.rows[1].title, n.rows[1].url, n.rows[1].right], ["Untitled", "", "2d"]);

// n8n
const e = P.n8n({ data: [{ status: "success", workflowId: "5", stoppedAt: "2026-01-01T11:55:00Z" }, { status: "error", workflowId: "6" }] }, now);
assert.deepEqual([e.rows[0].dot, e.rows[0].title, e.rows[0].right, e.rows[1].dot], ["#22C55E", "Workflow 5", "5m", "#F4505E"]);

// Garbage in -> empty, never a throw
for (const f of ["vercel", "resend", "notion", "n8n"]) assert.deepEqual(P[f](null).rows, []);
console.log("integrations parsers: ok");
