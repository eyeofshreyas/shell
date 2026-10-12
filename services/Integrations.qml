pragma Singleton

import QtQuick
import Quickshell
import Caelestia.I18n
import "scripts/integrations.js" as Parse

// Read-only dashboards for GitHub, Vercel, n8n, Notion and Resend.
// Keys live in the keyring (KeyringStorage "integrations"); requests carry them in headers, never in argv.
Singleton {
    id: root

    readonly property var defs: [
        {
            id: "github",
            name: "GitHub",
            kind: Tr.tr("Pull requests and CI"),
            colour: "#F4505E",
            icon: "merge",
            hint: Tr.tr("Personal access token (repo scope)"),
            open: "https://github.com/pulls"
        },
        {
            id: "vercel",
            name: "Vercel",
            kind: Tr.tr("Deployments"),
            colour: "#7C5CFF",
            icon: "rocket_launch",
            hint: Tr.tr("Access token"),
            open: "https://vercel.com/dashboard"
        },
        {
            id: "n8n",
            name: "n8n",
            kind: Tr.tr("Workflow runs"),
            colour: "#F29B38",
            icon: "account_tree",
            hint: Tr.tr("API key"),
            open: "",
            needsUrl: true
        },
        {
            id: "notion",
            name: "Notion",
            kind: Tr.tr("Recent pages"),
            colour: "#E8E8E8",
            icon: "description",
            hint: Tr.tr("Integration secret"),
            open: "https://www.notion.so"
        },
        {
            id: "resend",
            name: "Resend",
            kind: Tr.tr("Emails"),
            colour: "#22C55E",
            icon: "mail",
            hint: Tr.tr("API key (read access)"),
            open: "https://resend.com/emails"
        }
    ]

    // id -> { loading, error, fetched, headline, headlineSub, rows }
    property var results: ({})
    readonly property var stored: KeyringStorage.keyringData?.integrations ?? ({})
    readonly property bool keyringLoaded: KeyringStorage.loaded

    readonly property string githubQuery: `query {
  viewer {
    pullRequests(states: OPEN, first: 20, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes { number title url isDraft reviewDecision repository { nameWithOwner }
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } }
    }
    repositories(first: 10, ownerAffiliations: [OWNER], orderBy: {field: PUSHED_AT, direction: DESC}) {
      nodes { nameWithOwner url isArchived
        defaultBranchRef { name target { ... on Commit { statusCheckRollup { state } } } } }
    }
  }
  reviewRequested: search(query: "is:pr is:open review-requested:@me archived:false", type: ISSUE, first: 20) {
    issueCount
    nodes { ... on PullRequest { number title url author { login } repository { nameWithOwner } } }
  }
}`

    function configured(id: string): bool {
        const def = defs.find(d => d.id === id);
        return !!stored[id] && (!def?.needsUrl || !!stored[id + "Url"]);
    }

    function setKey(id: string, key: string, url: string): void {
        const def = defs.find(d => d.id === id);
        if (!def)
            return;
        KeyringStorage.setNestedField(["integrations", id], key.trim());
        if (def.needsUrl)
            KeyringStorage.setNestedField(["integrations", id + "Url"], url.trim().replace(/\/+$/, ""));
        if (configured(id))
            refresh(id);
        else
            put(id, {});
    }

    function removeKey(id: string): void {
        KeyringStorage.setNestedField(["integrations", id], "");
        KeyringStorage.setNestedField(["integrations", id + "Url"], "");
        put(id, {});
    }

    function refresh(id: string): void {
        if (!configured(id))
            return;
        put(id, Object.assign({}, results[id], {
            loading: true
        }));
        const key = stored[id];
        const done = view => put(id, Object.assign({
                fetched: Date.now()
            }, view));
        switch (id) {
        case "github":
            request("https://api.github.com/graphql", bearer(key, {
                "Content-Type": "application/json"
            }), {
                query: githubQuery
            }, (status, json) => done(status === 200 && json?.data ? parsed(Parse.github(json)) : failed(status)));
            break;
        case "vercel":
            request("https://api.vercel.com/v6/deployments?limit=6", bearer(key), null, (status, json) => done(status === 200 ? Parse.vercel(json) : failed(status)));
            break;
        case "n8n":
            request(`${stored.n8nUrl}/api/v1/executions?limit=5&includeData=false`, {
                "X-N8N-API-KEY": key
            }, null, (status, json) => done(status === 200 ? Parse.n8n(json) : failed(status)));
            break;
        case "notion":
            request("https://api.notion.com/v1/search", bearer(key, {
                "Notion-Version": "2022-06-28",
                "Content-Type": "application/json"
            }), {
                sort: {
                    direction: "descending",
                    timestamp: "last_edited_time"
                },
                page_size: 4
            }, (status, json) => done(status === 200 ? Parse.notion(json) : failed(status)));
            break;
        case "resend":
            request("https://api.resend.com/emails?limit=10", bearer(key), null, (status, json) => done(status === 200 ? Parse.resend(json) : failed(status)));
            break;
        }
    }

    function refreshAll(maxAgeMs: real): void {
        for (const def of defs) {
            if (!results[def.id]?.loading && Date.now() - (results[def.id]?.fetched ?? 0) >= maxAgeMs)
                refresh(def.id);
        }
    }

    function parsed(view: var): var {
        return view ?? {
            error: Tr.tr("Unexpected reply")
        };
    }

    function failed(status: int): var {
        return {
            error: status === 0 ? Tr.tr("No connection") : status === 401 || status === 403 ? Tr.tr("Key rejected (%1)").arg(status) : Tr.tr("HTTP %1").arg(status)
        };
    }

    function bearer(key: string, extra: var): var {
        return Object.assign({
            "Authorization": `Bearer ${key}`,
            "Accept": "application/json"
        }, extra);
    }

    function put(id: string, value: var): void {
        const next = Object.assign({}, results);
        next[id] = value;
        results = next;
    }

    function request(url: string, headers: var, body: var, done: var): void {
        const x = new XMLHttpRequest();
        x.open(body ? "POST" : "GET", url);
        for (const name in headers)
            x.setRequestHeader(name, headers[name]);
        x.timeout = 20000;
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            let json = null;
            try {
                json = JSON.parse(x.responseText);
            } catch (e) {}
            done(x.status, json);
        };
        x.send(body ? JSON.stringify(body) : undefined);
    }

    onKeyringLoadedChanged: {
        if (keyringLoaded)
            refreshAll(0);
    }

    Component.onCompleted: {
        if (keyringLoaded)
            refreshAll(0);
        else
            KeyringStorage.fetchKeyringData();
    }

    Timer {
        interval: 300000
        running: root.keyringLoaded
        repeat: true
        onTriggered: root.refreshAll(60000)
    }
}
