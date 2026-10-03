#!/usr/bin/env bash
# Print recent LLM CLI chats (Claude Code, Codex), newest last.
# Start it from ~/.bashrc:  [[ $- == *i* ]] && ~/github/linux-essentials/scripts/llm-splash.sh
# Show more chats:  LLM_SPLASH_N=20 llm-splash.sh

n=${LLM_SPLASH_N:-8}
cols=$(tput cols 2>/dev/null || echo 100)

rows=$({
  [[ -r ~/.claude/history.jsonl ]] && tail -n 500 ~/.claude/history.jsonl |
    jq -r 'select(.sessionId and (.display | startswith("/") | not)) | [(.timestamp/1000|floor), "claude", .sessionId, .project, .display] | @tsv' 2>/dev/null
  [[ -r ~/.codex/history.jsonl ]] && tail -n 500 ~/.codex/history.jsonl |
    jq -r '[.ts, "codex", .session_id, "-", .text] | @tsv' 2>/dev/null
} | sort -t$'\t' -k1,1nr | awk -F'\t' '!seen[$3]++' | head -n "$n" | tac)

while IFS=$'\t' read -r ts tool id dir text; do
  [[ -n $ts ]] || continue
  title=
  if [[ $tool == claude ]]; then
    f=$(compgen -G "$HOME/.claude/projects/*/$id.jsonl" | head -n 1)
    [[ -n $f ]] && title=$(grep -a '"type":"ai-title"' "$f" | tail -n 1 | jq -r '.aiTitle // empty' 2>/dev/null)
  else
    title=$(grep -F "\"$id\"" ~/.codex/session_index.jsonl 2>/dev/null | tail -n 1 | jq -r '.thread_name // empty' 2>/dev/null)
    f=$(find ~/.codex/sessions -name "*$id.jsonl" 2>/dev/null | head -n 1)
    [[ -n $f ]] && dir=$(head -n 1 "$f" | jq -r '.payload.cwd // "-"' 2>/dev/null)
  fi
  dir=${dir/#$HOME/\~}
  title=${title:-${text//\\n/ }}
  line=$(printf '%s  %-6s  %-20.20s  %s' "$(date -d "@$ts" '+%b %e %H:%M')" "$tool" "$dir" "$title")
  printf '%s\n' "${line:0:cols-1}"
done <<<"$rows"
