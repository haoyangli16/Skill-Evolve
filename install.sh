#!/bin/bash
set -e

# skill-evolve installer
# Installs the self-evolving skill pipeline for Claude Code

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"

echo "=== skill-evolve installer ==="
echo ""

# 1. Create directories
echo "[1/5] Creating directories..."
mkdir -p "$SKILLS_DIR"/{_meta,_archived,reflect,evolve,bin}

# 2. Copy skill files (don't overwrite existing)
echo "[2/5] Installing skill files..."

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ]; then
    echo "  SKIP $dst (already exists)"
  else
    cp "$src" "$dst"
    echo "  COPY $dst"
  fi
}

# Core pipeline files
copy_if_missing "$SCRIPT_DIR/skills/worklog.jsonl" "$SKILLS_DIR/worklog.jsonl"
copy_if_missing "$SCRIPT_DIR/skills/tricks.md" "$SKILLS_DIR/tricks.md"
copy_if_missing "$SCRIPT_DIR/skills/gaps.md" "$SKILLS_DIR/gaps.md"
copy_if_missing "$SCRIPT_DIR/skills/_confidence.yaml" "$SKILLS_DIR/_confidence.yaml"
copy_if_missing "$SCRIPT_DIR/skills/_graph.yaml" "$SKILLS_DIR/_graph.yaml"
copy_if_missing "$SCRIPT_DIR/skills/_evolution_log.yaml" "$SKILLS_DIR/_evolution_log.yaml"

# Meta-kernel files
copy_if_missing "$SCRIPT_DIR/skills/_meta/reflect.yaml" "$SKILLS_DIR/_meta/reflect.yaml"
copy_if_missing "$SCRIPT_DIR/skills/_meta/select.yaml" "$SKILLS_DIR/_meta/select.yaml"

# Skill commands (always update to latest)
cp "$SCRIPT_DIR/skills/reflect/SKILL.md" "$SKILLS_DIR/reflect/SKILL.md"
echo "  COPY $SKILLS_DIR/reflect/SKILL.md"
cp "$SCRIPT_DIR/skills/evolve/SKILL.md" "$SKILLS_DIR/evolve/SKILL.md"
echo "  COPY $SKILLS_DIR/evolve/SKILL.md"

# Hook scripts (always update to latest)
cp "$SCRIPT_DIR/skills/bin/auto-reflect-check.sh" "$SKILLS_DIR/bin/auto-reflect-check.sh"
cp "$SCRIPT_DIR/skills/bin/session-prime.sh" "$SKILLS_DIR/bin/session-prime.sh"
chmod +x "$SKILLS_DIR/bin/auto-reflect-check.sh" "$SKILLS_DIR/bin/session-prime.sh"
echo "  COPY + chmod hook scripts"

# Archive directory
mkdir -p "$SKILLS_DIR/_archived"

# 3. Configure hooks in settings.json
echo "[3/5] Configuring Claude Code hooks..."

if [ ! -f "$SETTINGS" ]; then
  # Create new settings.json with hooks
  cat > "$SETTINGS" << 'SETTINGS_EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/skills/bin/auto-reflect-check.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/skills/bin/session-prime.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
  echo "  Created $SETTINGS with hooks"
else
  # Check if hooks already configured
  if grep -q "auto-reflect-check" "$SETTINGS" 2>/dev/null; then
    echo "  SKIP hooks already configured in $SETTINGS"
  else
    # Try auto-merge with jq if available
    if command -v jq &>/dev/null; then
      echo "  Merging hooks into existing $SETTINGS (via jq)..."
      HOOKS_JSON=$(cat "$SCRIPT_DIR/hooks-snippet.json")
      jq --argjson hooks "$(echo "$HOOKS_JSON" | jq '.hooks')" '
        .hooks = ((.hooks // {}) * $hooks)
      ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
      echo "  MERGED hooks into $SETTINGS"
    else
      echo ""
      echo "  WARNING: $SETTINGS already exists and jq is not installed."
      echo "  Please manually merge the hooks from hooks-snippet.json into your settings.json."
      echo "  (Install jq to enable auto-merge: brew install jq / apt install jq)"
      echo ""
      echo "  See hooks-snippet.json for the hooks to add."
    fi
  fi
fi

# 4. Add CLAUDE.md snippet
echo "[4/5] CLAUDE.md behavioral rule..."
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  if grep -q "Skill Autopilot" "$CLAUDE_MD" 2>/dev/null; then
    echo "  SKIP already present in $CLAUDE_MD"
  else
    echo "" >> "$CLAUDE_MD"
    cat "$SCRIPT_DIR/claude-md-snippet.md" >> "$CLAUDE_MD"
    echo "  APPENDED autopilot rule to $CLAUDE_MD"
  fi
else
  cp "$SCRIPT_DIR/claude-md-snippet.md" "$CLAUDE_MD"
  echo "  CREATED $CLAUDE_MD with autopilot rule"
fi

# 5. Summary
echo "[5/5] Done!"
echo ""
echo "=== Installation complete ==="
echo ""
echo "What was installed:"
echo "  ~/.claude/skills/worklog.jsonl     — execution log (append-only)"
echo "  ~/.claude/skills/tricks.md         — technique library"
echo "  ~/.claude/skills/gaps.md           — unmet skill needs"
echo "  ~/.claude/skills/reflect/SKILL.md  — /reflect command"
echo "  ~/.claude/skills/evolve/SKILL.md   — /evolve command"
echo "  ~/.claude/skills/bin/*.sh          — automation hooks"
echo "  ~/.claude/settings.json            — Stop + SessionStart hooks"
echo "  ~/.claude/CLAUDE.md                — auto-worklog behavior"
echo ""
echo "How it works:"
echo "  1. Claude silently logs to worklog.jsonl after meaningful tasks"
echo "  2. After 5+ entries, the Stop hook nudges Claude to /reflect"
echo "  3. /reflect updates confidence scores, extracts tricks, identifies gaps"
echo "  4. When gaps reach 3 occurrences, /evolve generates new skills"
echo ""
echo "You don't need to do anything — just work normally."
echo "Run /reflect or /evolve manually anytime if you want."
