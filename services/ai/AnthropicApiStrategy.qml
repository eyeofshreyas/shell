import QtQuick

ApiStrategy {
    property int inputTokens: -1

    function buildEndpoint(model: AiModel): string {
        return model.endpoint;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        // Claude needs strictly alternating turns that start with the user
        const turns = [];
        for (const message of messages) {
            const role = message.role === "assistant" ? "assistant" : "user";
            const text = message.rawContent ?? "";
            if (text.length === 0)
                continue;
            if (turns.length > 0 && turns[turns.length - 1].role === role)
                turns[turns.length - 1].content += "\n\n" + text;
            else
                turns.push({
                    "role": role,
                    "content": text
                });
        }
        while (turns.length > 0 && turns[0].role !== "user")
            turns.shift();
        // ponytail: no tools, attachments or temperature for Claude; add when needed
        return Object.assign({
            "model": model.model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": turns,
            "stream": true
        }, model.extraParams);
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "x-api-key: \$\{${apiKeyEnvVarName}\}" -H "anthropic-version: 2023-06-01"`;
    }

    function parseResponseLine(line, message) {
        let clean = line.trim();
        if (clean.startsWith("data:"))
            clean = clean.slice(5).trim();
        // HTTP errors arrive as one bare JSON object instead of an event stream
        if (!clean.startsWith("{"))
            return {};
        let json;
        try {
            json = JSON.parse(clean);
        } catch (e) {
            return {};
        }
        switch (json.type) {
        case "content_block_delta":
            if (json.delta?.type === "text_delta") {
                message.content += json.delta.text;
                message.rawContent += json.delta.text;
            }
            return {};
        case "message_start":
            inputTokens = json.message?.usage?.input_tokens ?? -1;
            return {};
        case "message_delta": {
            const output = json.usage?.output_tokens ?? -1;
            return {
                tokenUsage: {
                    input: inputTokens,
                    output: output,
                    total: inputTokens >= 0 && output >= 0 ? inputTokens + output : -1
                }
            };
        }
        case "message_stop":
            return {
                finished: true
            };
        case "error": {
            const text = `**${json.error?.type ?? "error"}**: ${json.error?.message ?? ""}`;
            message.content += text;
            message.rawContent += text;
            return {
                finished: true
            };
        }
        }
        return {};
    }

    function reset() {
        inputTokens = -1;
    }
}
