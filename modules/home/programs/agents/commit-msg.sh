# Refuses a commit message that credits an AI or names the home folder: two of the rules that every
# agent reads (agents/AGENTS.md), checked here for all of them, and for the owner, in every
# repository. Git runs it beside each repository's own hooks. It reads the message up to the scissors
# line that `git commit -v` adds, so that the diff below it is not checked.
message=$(sed -n '/^# -* >8 -*$/q; /^#/!p' "$1")
# The agents and their makers by name; a bare "AI" or "LLM" counts only as "AI assistant" and the
# like, so that a person named Ai is not taken for one.
ai='claude|anthropic|openai|chatgpt|gpt-?[0-9o]+|codex|copilot|gemini|grok|kimi|moonshot|mistral|deepseek|qwen|glm|zhipu|opencode|cursor|aider|devin|openhands|(ai|llm)[- ]?(assistant|agent|model|bot)'
refuse() {
    echo "commit refused: $1" >&2
    exit 1
}
if printf '%s\n' "$message" | grep -qiE "^[[:space:]]*[a-z-]*(author|assisted|generated|signed-off)[a-z-]*-by:.*\b($ai)\b"; then
    refuse "a trailer credits an AI"
fi
if printf '%s\n' "$message" | grep -qiE "^[[:space:]]*(🤖|(generated|written|created|made|authored|assisted)( [a-z]+)? (with|by|using) .*\b($ai|ai|llm)\b)"; then
    refuse "a line says that an AI made it"
fi
if printf '%s\n' "$message" | grep -qF "$HOME/"; then
    refuse "the home folder's path is in the message"
fi
