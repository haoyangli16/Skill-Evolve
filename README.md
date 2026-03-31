# skill-evolve

A self-evolving skill and tricks pipeline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Claude automatically learns from your work, accumulates tricks, identifies skill gaps, and generates new skills over time.

**Zero effort from you** — just work normally. The system learns in the background.

## How it works

```
You work on your project normally
        |
        v
Claude silently logs what worked, what didn't, and what was missing
        |
        v
  worklog.jsonl  (append-only, one line per task)
        |
        v
  /reflect  (auto-triggered after 5+ entries)
     |        |         |
     v        v         v
confidence  tricks    gaps
 scores     .md       .md
 updated    (new      (unmet
            tips)     needs)
        |
        v  (when 3+ gaps accumulate)
  /evolve
     |        |         |
     v        v         v
  new skill  tricks    dead skills
  YAML       folded    archived
  generated  into      (can
             skills    resurrect)
```

## What it does

| Layer | What | When | Your effort |
|-------|------|------|-------------|
| **Worklog** | Logs tasks, tricks learned, skill gaps | After meaningful work | None (Claude does it) |
| **Reflect** | Updates confidence scores, extracts tricks, tracks gaps | Auto after 5 entries | None (hook triggers it) |
| **Evolve** | Promotes gaps to skills, folds tricks in, prunes dead skills | When you say `/evolve` | One command |

### The key idea: Skills = Base technique + Accumulated tricks

```
+------------------------------------------+
|            api_development               |
|                                          |
|  Base: REST API design, routing, auth    |
|                                          |
|  Tricks (grow over time):               |
|    +- "Zod-first schemas" (TS APIs)     |
|    +- "Middleware ordering" (Express)    |
|    +- "OpenAPI spec first" (team APIs)  |
|    +- ... (accumulates with each use)   |
+------------------------------------------+
```

A skill used 20 times across different projects has a rich tricks library that a new skill won't. Skills get better the more you use them.

## Install

```bash
git clone https://github.com/haoyangli16/Skill-Evolve.git
cd skill-evolve
chmod +x install.sh
./install.sh
```

The installer:
- Copies skill files to `~/.claude/skills/` (won't overwrite your data files)
- Configures Claude Code hooks in `~/.claude/settings.json`
- Adds the autopilot behavioral rule to `~/.claude/CLAUDE.md`
- Always updates skill commands and hook scripts to latest version
- Safe to re-run (idempotent for data, always-latest for commands)

> **Note**: If you already have a `~/.claude/settings.json`, the installer won't modify it automatically. It will print instructions and save the hooks to `hooks-snippet.json` for you to merge manually.

### Manual install

If you prefer to install manually:

1. Copy the `skills/` directory contents to `~/.claude/skills/`
2. Make scripts executable: `chmod +x ~/.claude/skills/bin/*.sh`
3. Merge the hooks from [`hooks-snippet.json`](hooks-snippet.json) into your `~/.claude/settings.json`
4. Append [`claude-md-snippet.md`](claude-md-snippet.md) to your `~/.claude/CLAUDE.md`

<details>
<summary>Hooks to add to settings.json</summary>

```json
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
```

</details>

## Usage

### Automatic (recommended)

Just work normally. The system runs in the background:

1. Claude logs to `worklog.jsonl` after completing meaningful tasks
2. The `Stop` hook checks for unprocessed entries after each response
3. When 5+ entries accumulate, Claude auto-runs `/reflect`
4. When gaps reach 3 occurrences, Claude tells you to run `/evolve`

### Manual commands

| Command | What it does |
|---------|-------------|
| `/reflect` | Process worklog: update confidence, extract tricks, identify gaps |
| `/evolve` | Promote gap candidates to skills, fold tricks, prune dead skills |

### Worklog format

Each entry is one JSON line in `worklog.jsonl`:

```jsonl
{"ts":"2026-03-30T10:00:00Z","skill":"api_development","task":"Build REST API","outcome":"success","trick":"Used zod for validation","duration_min":15}
{"ts":"2026-03-30T11:30:00Z","skill":null,"task":"Generate PDF report","outcome":"partial","gap":"No PDF generation skill","duration_min":25}
```

| Field | Required | Description |
|-------|----------|-------------|
| `ts` | yes | ISO 8601 timestamp |
| `skill` | yes | Skill ID used, or `null` if none matched |
| `task` | yes | What was done (1 sentence) |
| `outcome` | yes | `success`, `partial`, or `failure` |
| `trick` | no | Technique worth remembering |
| `gap` | no | Skill that was needed but didn't exist |
| `duration_min` | no | Approximate minutes spent |

## File structure

```
~/.claude/skills/
  worklog.jsonl          <- append-only execution log
  tricks.md              <- accumulated techniques by domain
  gaps.md                <- unmet skill needs tracker
  _confidence.yaml       <- skill scores (updated by /reflect)
  _graph.yaml            <- skill relationships
  _evolution_log.yaml    <- change history
  _archived/             <- pruned skills (can resurrect)
  _meta/
    reflect.yaml         <- reflection algorithm spec
    select.yaml          <- skill selection algorithm spec
  reflect/
    SKILL.md             <- /reflect slash command
  evolve/
    SKILL.md             <- /evolve slash command
  bin/
    auto-reflect-check.sh  <- Stop hook (nudges reflection)
    session-prime.sh       <- SessionStart hook (context priming)
```

## Confidence scoring

| Event | Score change |
|-------|-------------|
| Task success | +0.05 |
| Partial success | +0.02 |
| Task failure | -0.10 |
| Unused 2+ weeks | -0.02/week |

Scores are capped between 0.10 and 0.99.

## How evolution works

1. You work normally. Claude logs gaps when skills are missing.
2. `/reflect` increments gap occurrence counts in `gaps.md`.
3. When a gap reaches **3 occurrences**, it becomes a "candidate".
4. `/evolve` generates a skill YAML from the candidate:
   - Synthesizes technique from all gap contexts
   - Sets initial confidence to 0.70
   - Adds edges to the skill graph
   - Marks gap as "promoted"
5. The new skill is available for future tasks.

## Design philosophy

This system was designed after a v1 attempt that failed. Lessons learned:

| v1 (failed) | v2 (this repo) | Why |
|-------------|----------------|-----|
| 5-kernel pipeline (decompose/select/execute/validate/reflect) | 3 layers (worklog/reflect/evolve) | Claude Code is one agent, not a microservice |
| tmux worker queue system | Claude Code is the executor | No queue/worker abstraction needed |
| YAML execution traces | JSONL worklog (one-liner, grep-friendly) | Minimal overhead = actually gets used |
| `memory/patterns/*.yaml` | `tricks.md` (human-readable markdown) | Low ceremony, searchable, one file |
| Auto-triggered kernel pipeline | Hooks + behavioral CLAUDE.md rule | Reliable triggers that actually fire |

**The core insight**: over-engineered systems fail silently. A system that costs 5 seconds to log and can be grepped from the terminal will accumulate more data than a formal YAML pipeline that nobody remembers to invoke.

## Customization

### Add your own starter skills

Edit `~/.claude/skills/_confidence.yaml` to add skills relevant to your work:

```yaml
my_domain:
  my_skill:
    score: 0.80
    usage_count: 0
    success_count: 0
    last_used: null
    trend: stable
    notes: "Description of what this skill does"
```

### Change the reflect threshold

Edit `~/.claude/skills/bin/auto-reflect-check.sh`, line:
```bash
REFLECT_THRESHOLD=5  # Change to your preference
```

### Add skill graph edges

Edit `~/.claude/skills/_graph.yaml`:
```yaml
- from: my_new_skill
  to: existing_skill
  type: requires|enables|enhances
  strength: 0.8
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (any recent version with hooks support)
- bash (macOS/Linux)

## License

MIT
