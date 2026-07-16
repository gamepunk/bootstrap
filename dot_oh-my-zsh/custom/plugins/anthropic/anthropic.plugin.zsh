# Anthropic/DeepSeek API config for Claude Code
# Token is lazy-loaded from macOS Keychain on first use

export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max

function _load_anthropic_token() {
  if [[ -z "$_ANTHROPIC_TOKEN_LOADED" ]]; then
    export ANTHROPIC_AUTH_TOKEN=$(security find-generic-password -w -s "deepseek-api-key" 2>/dev/null || echo "")
    export _ANTHROPIC_TOKEN_LOADED=1
  fi
}
add-zsh-hook precmd _load_anthropic_token
