// Runs the Claude strategy's functions under node (QML type annotations stripped).
import fs from "node:fs";
import assert from "node:assert/strict";

const src = fs.readFileSync(new URL("../services/ai/AnthropicApiStrategy.qml", import.meta.url), "utf8")
  .replace(/^import.*$/gm, "").replace(/ApiStrategy \{/, "").replace(/\}\s*$/, "")
  .replace(/property int inputTokens: -1/, "")
  .replace(/\(([^)]*)\): string \{/g, (_, a) => `(${a.replace(/: \w+/g, "")}) {`)
  .replace(/function (\w+)\(([^)]*)\)/g, (_, n, a) => `function ${n}(${a.replace(/: [\w<>]+/g, "")})`);
const S = new Function(`let inputTokens = -1; ${src}; return { buildRequestData, buildAuthorizationHeader, parseResponseLine, reset };`)();

const model = { model: "claude-sonnet-5", extraParams: {} };
const req = S.buildRequestData(model, [
  { role: "assistant", rawContent: "hi, ask me" }, { role: "user", rawContent: "a" }, { role: "user", rawContent: "b" },
  { role: "assistant", rawContent: "" }, { role: "user", rawContent: "c" },
], "sys", 0.5, []);
assert.deepEqual(req.messages, [{ role: "user", content: "a\n\nb\n\nc" }]);
assert.equal(req.system, "sys");
assert.equal(req.stream, true);
assert.equal("temperature" in req, false);
assert.match(S.buildAuthorizationHeader("API_KEY"), /x-api-key: \$\{API_KEY\}.*anthropic-version/);

const msg = { content: "", rawContent: "" };
assert.deepEqual(S.parseResponseLine("event: message_start", msg), {});
S.parseResponseLine('data: {"type":"message_start","message":{"usage":{"input_tokens":12}}}', msg);
S.parseResponseLine('data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hel"}}', msg);
S.parseResponseLine('data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"lo"}}', msg);
S.parseResponseLine('data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"x"}}', msg);
assert.equal(msg.content, "Hello");
assert.deepEqual(S.parseResponseLine('data: {"type":"message_delta","usage":{"output_tokens":5}}', msg).tokenUsage, { input: 12, output: 5, total: 17 });
assert.equal(S.parseResponseLine('data: {"type":"message_stop"}', msg).finished, true);
const err = { content: "", rawContent: "" };
assert.equal(S.parseResponseLine('{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}', err).finished, true);
assert.match(err.content, /invalid x-api-key/);
console.log("anthropic strategy: ok");
