---
name: reflect
description: "Lightweight session reflection: read worklog, update confidence scores, extract tricks, identify skill gaps. Run at session end or after significant work."
user_invocable: true
---

# /reflect — Skill Evolution Reflection

Reads the worklog, updates confidence scores, extracts tricks, and identifies skill gaps.
This is the engine that makes the skill system learn from real work.

## When to Run

- **Session end**: Before closing a productive session
- **After significant work**: Completed a complex task or multi-step project
- **Periodically**: When worklog has 10+ unprocessed entries
- **Integrated into /sc:save**: Runs automatically as part of session save

## Process

### Step 1: Read the Worklog

Read `~/.claude/skills/worklog.jsonl`. Each line is a JSON object:

```jsonl
{"ts":"...","skill":"api_development","task":"Build REST API","outcome":"success","trick":"Used zod for validation","duration_min":15}
{"ts":"...","skill":null,"task":"Generate PDF","outcome":"partial","gap":"No PDF generation skill","duration_min":25}
```

Find entries since the last reflection. The last reflection timestamp is stored as
the final line starting with `# reflected:` at the end of the worklog file.

If there are no new entries, report "Nothing to reflect on" and stop.

### Step 2: Update Confidence Scores

Read `~/.claude/skills/_confidence.yaml`. For each skill mentioned in new worklog entries:

| Outcome | Score Change |
|---------|-------------|
| `success` | +0.05 |
| `partial` | +0.02 |
| `failure` | -0.10 |

Also apply **weekly decay** to skills NOT used in the new entries:
- Check `last_used` dates
- If unused for 2+ weeks: -0.02 per week (capped at min 0.10)

Update the YAML:
- `score`: new calculated score (cap at 0.99)
- `usage_count`: increment
- `success_count`: increment on success
- `last_used`: update to latest usage date
- `trend`: recalculate (improving if last 3 uses all success, declining if last 3 have failures)

Write changes back to `_confidence.yaml`.

### Step 3: Extract Tricks

For each worklog entry that has a non-empty `trick` field:

1. Read `~/.claude/skills/tricks.md`
2. Find the section for the entry's `skill` domain (e.g., `## api_development`)
3. Check if a similar trick already exists (fuzzy match on description)
4. If new, append the trick in format:
   ```
   - **Trick Name** (YYYY-MM-DD | context): description
   ```
5. If the skill section doesn't exist yet, create it

### Step 4: Identify Gaps

For each worklog entry where `skill` is `null` or `outcome` is `failure` with a `gap` field:

1. Read `~/.claude/skills/gaps.md`
2. Search for an existing gap with the same name/category
3. If found: increment occurrences, add the date and context
4. If new: create a new gap entry with 1 occurrence

If any gap reaches **3+ occurrences**, change its status to `candidate` and notify:
```
🎯 Gap promoted to candidate: [gap_name] (N occurrences)
   Ready for /evolve to generate a skill.
```

### Step 5: Mark Reflection Complete

Append to `worklog.jsonl`:
```
# reflected: YYYY-MM-DDTHH:MM:SSZ | entries: N | tricks: N | gaps: N | confidence_updates: N
```

### Step 6: Report Summary

Output a brief reflection summary:

```
## 🔄 Reflection Complete

**Worklog entries processed**: N
**Confidence updates**:
  - api_development: 0.85 → 0.90 (+0.05)
  - debugging: 0.85 (unchanged)
**New tricks learned**: N
  - [trick name] → [skill domain]
**Gaps identified**: N
  - [gap name]: M occurrences (tracking|candidate)
**Evolution candidates**: N ready for /evolve
```

## Worklog Entry Format

When you (Claude Code) complete a task during normal work, append to worklog:

```bash
echo '{"ts":"TIMESTAMP","skill":"SKILL_ID_OR_NULL","task":"SHORT_DESCRIPTION","outcome":"success|partial|failure","trick":"OPTIONAL_LEARNING","gap":"OPTIONAL_UNMET_NEED","duration_min":N}' >> ~/.claude/skills/worklog.jsonl
```

**Fields**:
- `ts`: ISO 8601 timestamp
- `skill`: skill ID used (from _confidence.yaml domains), or `null` if no skill matched
- `task`: what was done (1 sentence)
- `outcome`: `success`, `partial`, or `failure`
- `trick`: optional — any technique discovered worth remembering
- `gap`: optional — description of skill that was needed but didn't exist
- `duration_min`: approximate time spent

## Integration Points

- **/sc:save** should run /reflect automatically
- **/sc:load** should check if worklog has unprocessed entries and suggest reflecting
- **Normal work**: Claude Code should append to worklog after completing meaningful tasks
  (not every tiny edit — use judgment: tasks that took 5+ minutes or taught something)

## What This Skill Does NOT Do

- Does not generate new skills (that's `/evolve`)
- Does not modify skill YAML files (only `_confidence.yaml`, `tricks.md`, `gaps.md`)
- Does not run the old tmux orchestrator or queue system
- Does not require formal execution traces — the worklog IS the trace
