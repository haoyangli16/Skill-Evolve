#!/bin/bash
# session-prime.sh — SessionStart hook that re-injects skill context
#
# Called on session start, resume, and after context compaction.
# Outputs key skill system state so Claude has context for worklog/tricks.

WORKLOG="$HOME/.claude/skills/worklog.jsonl"

MSG=""

# Count unprocessed worklog entries
if [ -f "$WORKLOG" ] && [ -s "$WORKLOG" ]; then
  LAST_REFLECT_LINE=$(grep -n "^# reflected:" "$WORKLOG" 2>/dev/null | tail -1 | cut -d: -f1)
  if [ -z "$LAST_REFLECT_LINE" ]; then
    UNPROCESSED=$(grep -c "^{" "$WORKLOG" 2>/dev/null)
  else
    TOTAL_LINES=$(wc -l < "$WORKLOG" | tr -d ' ')
    REMAINING=$((TOTAL_LINES - LAST_REFLECT_LINE))
    if [ "$REMAINING" -gt 0 ]; then
      UNPROCESSED=$(tail -n "$REMAINING" "$WORKLOG" 2>/dev/null | grep -c "^{")
    else
      UNPROCESSED=0
    fi
  fi
  UNPROCESSED=$((UNPROCESSED + 0))

  if [ "$UNPROCESSED" -gt 0 ]; then
    MSG="[skill-autopilot] $UNPROCESSED unprocessed worklog entries pending reflection."
  fi
fi

if [ -n "$MSG" ]; then
  echo "$MSG"
fi

echo "[skill-autopilot] Skill evolution active. Worklog: ~/.claude/skills/worklog.jsonl | Tricks: ~/.claude/skills/tricks.md"

exit 0
