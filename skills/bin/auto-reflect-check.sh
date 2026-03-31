#!/bin/bash
# auto-reflect-check.sh — Stop hook that nudges reflection when worklog accumulates
#
# Called by Claude Code's Stop hook after each response.
# Checks unprocessed worklog entries and outputs a nudge if threshold met.
# Output is fed back to Claude as context for the next turn.

WORKLOG="$HOME/.claude/skills/worklog.jsonl"
GAPS="$HOME/.claude/skills/gaps.md"

# Exit silently if worklog doesn't exist or is empty
[ -f "$WORKLOG" ] || exit 0
[ -s "$WORKLOG" ] || exit 0

# Count entries since last reflection marker
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

# Ensure UNPROCESSED is a clean integer
UNPROCESSED=$((UNPROCESSED + 0))

# Check for evolution candidates in gaps.md
CANDIDATES=0
if [ -f "$GAPS" ]; then
  CANDIDATES=$(grep -c "^- \*\*Status\*\*: candidate" "$GAPS" 2>/dev/null)
  CANDIDATES=$((CANDIDATES + 0))
fi

# Nudge thresholds
REFLECT_THRESHOLD=5
MSG=""

if [ "$UNPROCESSED" -ge "$REFLECT_THRESHOLD" ]; then
  MSG="[skill-autopilot] $UNPROCESSED unprocessed worklog entries. Run /reflect to update confidence scores, extract tricks, and identify gaps."
fi

if [ "$CANDIDATES" -gt 0 ]; then
  if [ -n "$MSG" ]; then
    MSG="$MSG Also: $CANDIDATES evolution candidate(s) ready — run /evolve."
  else
    MSG="[skill-autopilot] $CANDIDATES evolution candidate(s) ready in gaps.md — run /evolve to promote to skills."
  fi
fi

if [ -n "$MSG" ]; then
  echo "$MSG"
fi

exit 0
