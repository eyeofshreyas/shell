.pragma library

// Turns each service's API reply into { headline, headlineSub, rows: [{ dot, title, sub, right, url }] }.
// Pure functions (no QML, no network) so scripts/test_integrations.mjs can run them under node.

const GREEN = "#22C55E";
const RED = "#F4505E";
const AMBER = "#F5A524";
const BLUE = "#8AB4F8";
const GREY = "#6B7079";

function ago(when, now) {
    const t = typeof when === "number" ? when : Date.parse(when);
    const s = ((now ?? Date.now()) - t) / 1000;
    if (!isFinite(s))
        return "";
    if (s < 60)
        return "now";
    if (s < 3600)
        return Math.floor(s / 60) + "m";
    if (s < 86400)
        return Math.floor(s / 3600) + "h";
    return Math.floor(s / 86400) + "d";
}

function safeUrl(url) {
    return typeof url === "string" && url.startsWith("https://") ? url : "";
}

function ciColour(state) {
    switch (state) {
    case "SUCCESS":
        return GREEN;
    case "FAILURE":
    case "ERROR":
        return RED;
    case "PENDING":
    case "EXPECTED":
        return AMBER;
    default:
        return GREY;
    }
}

function nodes(x) {
    return Array.isArray(x?.nodes) ? x.nodes.filter(n => n) : [];
}

const REVIEW = {
    APPROVED: "approved",
    CHANGES_REQUESTED: "changes requested",
    REVIEW_REQUIRED: "needs review"
};

function github(root) {
    const viewer = root?.data?.viewer;
    if (!viewer)
        return null;
    const shortRepo = r => String(r ?? "").split("/").pop();
    const failingMain = nodes(viewer.repositories).filter(r => !r.isArchived && r.defaultBranchRef?.target?.statusCheckRollup?.state && ciColour(r.defaultBranchRef.target.statusCheckRollup.state) === RED).map(r => ({
                dot: RED,
                title: `${shortRepo(r.nameWithOwner)} ${r.defaultBranchRef.name}`,
                sub: "CI failing",
                right: "",
                url: safeUrl(r.url) ? safeUrl(r.url) + "/actions" : ""
            }));
    const prs = nodes(viewer.pullRequests);
    const reviews = nodes(root.data.reviewRequested);
    const prRows = prs.map(p => ({
                dot: ciColour(nodes(p.commits)[0]?.commit?.statusCheckRollup?.state),
                title: `${shortRepo(p.repository?.nameWithOwner)}#${p.number} ${p.title}`,
                sub: [p.isDraft ? "draft" : "", REVIEW[p.reviewDecision] ?? ""].filter(x => x).join(" · "),
                right: "",
                url: safeUrl(p.url)
            }));
    const reviewRows = reviews.map(p => ({
                dot: BLUE,
                title: `${shortRepo(p.repository?.nameWithOwner)}#${p.number} ${p.title}`,
                sub: p.author?.login ? "review requested · @" + p.author.login : "review requested",
                right: "",
                url: safeUrl(p.url)
            }));
    const failing = failingMain.length;
    return {
        headline: `${prs.length} PRs · ${root.data.reviewRequested?.issueCount ?? reviews.length} to review` + (failing ? ` · ${failing} CI failing` : ""),
        headlineSub: "",
        rows: [...failingMain.slice(0, 2), ...reviewRows.slice(0, 2), ...prRows].slice(0, 5)
    };
}

function vercel(json, now) {
    const done = ["READY", "ERROR", "CANCELED"];
    const rows = (json?.deployments ?? []).filter(d => done.includes(d.state)).slice(0, 4).map(d => {
        const m = d.meta ?? {};
        return {
            dot: d.state === "READY" ? GREEN : RED,
            title: String(d.name ?? ""),
            sub: [m.githubCommitRef ?? m.gitlabCommitRef, m.githubCommitMessage ?? m.gitlabCommitMessage].filter(x => x).join(" · "),
            right: ago(d.createdAt, now),
            url: d.url ? safeUrl("https://" + d.url) : ""
        };
    });
    return {
        headline: "",
        headlineSub: "",
        rows
    };
}

function resend(json, now) {
    const to = e => String(Array.isArray(e.to) ? e.to[0] : e.to ?? "?").split("@")[0];
    const total = json?.total ?? json?.count;
    return {
        headline: total != null ? String(total) : "",
        headlineSub: total != null ? "emails" : "",
        rows: (json?.data ?? []).slice(0, 4).map(e => ({
                    dot: e.last_event === "delivered" ? GREEN : RED,
                    title: to(e),
                    sub: e.subject ?? "",
                    right: ago(e.created_at, now),
                    url: ""
                }))
    };
}

function notionTitle(page) {
    const first = arr => arr?.[0]?.plain_text;
    if (page.object === "database")
        return first(page.title) || "Untitled";
    for (const p of Object.values(page.properties ?? {})) {
        if (p.type === "title" && first(p.title))
            return first(p.title);
    }
    return "Untitled";
}

function notion(json, now) {
    return {
        headline: "",
        headlineSub: "",
        rows: (json?.results ?? []).slice(0, 4).map(p => ({
                    dot: GREY,
                    title: (p.icon?.type === "emoji" ? p.icon.emoji + " " : "") + notionTitle(p),
                    sub: "",
                    right: ago(p.last_edited_time, now),
                    url: safeUrl(p.url)
                }))
    };
}

function n8n(json, now) {
    return {
        headline: "",
        headlineSub: "",
        rows: (json?.data ?? []).slice(0, 4).map(e => ({
                    dot: e.status === "success" ? GREEN : e.status === "running" || e.status === "waiting" ? AMBER : RED,
                    title: `Workflow ${e.workflowId ?? ""}`.trim(),
                    sub: e.status ?? "",
                    right: ago(e.stoppedAt ?? e.startedAt, now),
                    url: ""
                }))
    };
}
