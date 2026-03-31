#!/bin/bash
# session-prime.sh — SessionStart hook that re-injects skill context
#
# Called on session start, resume, and after context compaction.
# Outputs key skill system state so Claude has context for worklog/tricks.

WORKLOG="$HOME/.claude/skills/worklog.jsonl"
TRICKS="$HOME/.claude/skills/tricks.md"
CONFIDENCE="$HOME/.claude/skills/_confidence.yaml"

MSG=""

# Count unprocessed worklog entries
if [ -f "$WORKLOG" ]; then
  LAST_REFLECT_LINE=$(grep -n "^# reflected:" "$WORKLOG" 2>/dev/null | tail -1 | cut -d: -f1)
  if [ -z "$LAST_REFLECT_LINE" ]; then
    UNPROCESSED=$(grep -c "^{" "$WORKLOG" 2>/dev/null || echo 0)
  else
    TOTAL_LINES=$(wc -l < "$WORKLOG" | tr -d ' ')
    REMAINING=$((TOTAL_LINES - LAST_REFLECT_LINE))
    UNPROCESSED=$(tail -n "$REMAINING" "$WORKLOG" 2>/dev/null | grep -c "^{" || echo 0)
  fi

  if [ "$UNPROCESSED" -gt 0 ]; then
    MSG="[skill-autopilot] $UNPROCESSED unprocessed worklog entries pending reflection."
  fi
fi

# Output skill system status
if [ -n "$MSG" ]; then
  echo "$MSG"
fi

echo "[skill-autopilot] Skill evolution active. Worklog: ~/.claude/skills/worklog.jsonl | Tricks: ~/.claude/skills/tricks.md"

exit 0
