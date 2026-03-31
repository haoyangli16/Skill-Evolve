# Skill Autopilot (auto-worklog + auto-reflect)
# Add this block to your ~/.claude/CLAUDE.md or project CLAUDE.md

# ===================================================
# Skill Autopilot (auto-worklog + auto-reflect)
# ===================================================
# After completing meaningful work (5+ min tasks, or learned something new),
# silently append ONE line to ~/.claude/skills/worklog.jsonl:
#
#   echo '{"ts":"TIMESTAMP","skill":"SKILL_OR_NULL","task":"DESCRIPTION","outcome":"success|partial|failure","trick":"OPTIONAL","gap":"OPTIONAL","duration_min":N}' >> ~/.claude/skills/worklog.jsonl
#
# Rules:
# - Only log tasks worth remembering (not every tiny edit)
# - "trick" = any technique discovered worth remembering for next time
# - "gap" = skill that was needed but didn't exist (skill should be null)
# - Do this quietly — don't mention it to the user unless they ask
# - When the Stop hook reports 5+ unprocessed entries, run /reflect automatically
# - When the Stop hook reports evolution candidates, mention it to the user
# - Read ~/.claude/skills/tricks.md for relevant tricks before complex tasks
