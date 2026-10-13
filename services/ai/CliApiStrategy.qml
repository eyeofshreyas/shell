import QtQuick

// Runs the claude or codex CLI, so chats use the user's subscription instead of an API key.
ApiStrategy {
    property string flavor: "claude"

    function quote(s: string): string {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function buildEndpoint(model: AiModel): string {
        return "";
    }

    // The CLIs are stateless here, so the whole chat goes in as one transcript
    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        const turns = messages.filter(m => (m.rawContent ?? "").length > 0);
        let prompt = turns.length === 1 ? turns[0].rawContent : turns.map(m => `${m.role === "assistant" ? "Assistant" : "User"}: ${m.rawContent}`).join("\n\n") + "\n\nAssistant:";
        if (flavor === "codex")
            prompt = `${systemPrompt}\n\n${prompt}`;
        return {
            "prompt": prompt,
            "system": systemPrompt
        };
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return "";
    }

    function buildCliCommand(model: AiModel, data): string {
        const run = flavor === "claude"
            ? `claude -p --model ${model.model} --output-format stream-json --verbose --include-partial-messages --tools "" --no-session-persistence --settings '{"disableAllHooks":true}' --strict-mcp-config --disable-slash-commands --setting-sources "" --system-prompt ${quote(data.system)}`
            : `codex exec --json --skip-git-repo-check -s read-only --ephemeral ${model.model ? "-m " + model.model : ""} -`;
        return `cd /tmp && printf %s ${quote(data.prompt)} | ${run} 2>&1\n`;
    }

    function parseResponseLine(line, message) {
        const clean = line.trim();
        let json = null;
        if (clean.startsWith("{")) {
            try {
                json = JSON.parse(clean);
            } catch (e) {}
        }
        // Anything that isn't an event is a shell or CLI error, e.g. command not found
        if (!json) {
            message.content += clean + "\n";
            message.rawContent += clean + "\n";
            return {};
        }
        if (flavor === "claude") {
            if (json.type === "stream_event" && json.event?.delta?.type === "text_delta") {
                message.content += json.event.delta.text;
                message.rawContent += json.event.delta.text;
            } else if (json.type === "result") {
                if (json.is_error) {
                    message.content += `**error**: ${json.result}`;
                    message.rawContent += `**error**: ${json.result}`;
                }
                return {
                    finished: true
                };
            }
            return {};
        }
        if (json.type === "item.completed" && json.item?.type === "agent_message") {
            const text = (message.content.length > 0 ? "\n\n" : "") + json.item.text;
            message.content += text;
            message.rawContent += text;
        } else if (json.type === "turn.failed") {
            message.content += `**error**: ${json.error?.message ?? ""}`;
            message.rawContent += `**error**: ${json.error?.message ?? ""}`;
            return {
                finished: true
            };
        } else if (json.type === "turn.completed") {
            return {
                finished: true
            };
        }
        return {};
    }
}
