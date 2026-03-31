---
name: evolve
description: "Batch skill evolution: promote gaps to skills, fold tricks into skill techniques, prune dead skills, update the skill graph. Run when gaps accumulate or periodically."
user_invocable: true
---

# /evolve — Skill System Evolution

The deliberate, batch process that grows the skill system. Promotes gap candidates to
real skills, folds accumulated tricks into existing skill techniques, prunes unused
skills, and keeps the graph current.

## When to Run

- **Explicitly**: User says `/evolve`
- **When prompted**: `/reflect` reports evolution candidates are ready
- **Periodically**: Monthly maintenance of the skill system
- **After major projects**: When a project revealed new patterns worth codifying

## Process

### Step 1: Read Current State

Read these files to understand what needs to evolve:

```
~/.claude/skills/gaps.md          → candidates for new skills (3+ occurrences)
~/.claude/skills/tricks.md        → techniques to fold into existing skills
~/.claude/skills/_confidence.yaml → scores for pruning decisions
~/.claude/skills/_graph.yaml      → current skill relationships
~/.claude/skills/_evolution_log.yaml → history of changes
```

### Step 2: Promote Gap Candidates → Skills

For each gap in `gaps.md` with status `candidate` (3+ occurrences):

1. **Analyze the gap**: What contexts did it appear in? What was the user trying to do?
2. **Check for existing overlap**: Is there an existing skill that could be extended instead?
3. **Decision**:
   - If an existing skill covers 70%+ of the gap → extend that skill with new tricks/techniques
   - If genuinely new → generate a new skill YAML

**New skill generation**:

```yaml
# Write to: ~/.claude/skills/{domain}/{skill_id}.yaml
skill:
  id: {skill_id}
  domain: {research|development|operations}
  version: 1.0.0
  generated_by: evolve
  generated_from: gap_{gap_name}

  description: |
    {What this skill does, derived from gap contexts}

  triggers:
    keywords: [{extracted from gap contexts}]
    contexts: [{when this skill applies}]

  techniques:
    default: |
      {Best approach synthesized from gap occurrences and any related tricks}

    # Context-specific techniques pulled from tricks.md
    {context_name}: |
      {Specific technique for this context}

  tricks:
    # Tricks from tricks.md that belong to this skill
    - name: "{trick name}"
      context: "{when to apply}"
      technique: "{what to do}"

  tools:
    primary: [{best tools for this skill}]
    optional: [{helpful but not required}]
```

After generating:
- Set initial confidence to `0.70` in `_confidence.yaml`
- Add graph edges to `_graph.yaml` (requires, enables, enhances relationships)
- Update gap status in `gaps.md` from `candidate` → `promoted`

### Step 3: Fold Tricks into Skills

For each section in `tricks.md`:

1. Find the corresponding skill YAML (e.g., `## api_development` → `development/api_development.yaml`)
2. Check if the skill has a `tricks:` section
3. If not, add one
4. For each trick not yet in the skill's tricks section, add it:

```yaml
tricks:
  - name: "Zod-first schemas"
    learned: "2026-03-30"
    context: "TypeScript REST APIs"
    technique: "Define zod schemas first, derive types with z.infer<>"
```

**Why fold tricks into skills?** So that during skill selection, the agent gets both
the default technique AND the accumulated tricks for that domain. Skills become
richer over time as tricks accumulate — this is the "skills combine with multiple
tricks based on different usage" pattern.

### Step 4: Prune Dead Skills

Check `_confidence.yaml` for skills matching ALL of:
- `score` < 0.30
- `last_used` is null OR > 8 weeks ago
- `usage_count` < 3

For matching skills:
1. Don't delete — move to `~/.claude/skills/_archived/`
2. Remove from `_confidence.yaml`
3. Remove edges from `_graph.yaml`
4. Log the archival

**Resurrection**: If an archived skill's domain appears in `gaps.md` later,
check the archive before generating a new skill.

### Step 5: Update the Graph

For any new or modified skills:

1. Analyze what the skill `requires` (hard dependencies)
2. Analyze what it `enables` (soft dependencies)
3. Analyze what it `enhances` (makes better)
4. Add edges to `_graph.yaml`:

```yaml
- from: {new_skill_id}
  to: {related_skill_id}
  type: {requires|enables|enhances}
  strength: {0.0-1.0}
  note: "{why this relationship exists}"
```

5. Update the `traversal` section if new entry points or leaf nodes were created

### Step 6: Log Everything

Append to `_evolution_log.yaml`:

```yaml
- timestamp: {ISO 8601}
  type: {skill_promoted|skill_extended|skill_archived|tricks_folded|graph_updated}
  details: "{description}"
  evidence: "{what triggered this change}"
  changes:
    - "{specific file change}"
```

### Step 7: Report

Output a summary:

```
## 🧬 Evolution Complete

**Skills promoted**: N
  - {skill_id}: from gap "{gap_name}" (N occurrences)
    Domain: {domain}, Initial confidence: 0.70
    Graph edges added: N

**Skills extended**: N
  - {skill_id}: +N tricks folded in

**Skills archived**: N
  - {skill_id}: unused {N} weeks, confidence {score}

**Graph updates**: N new edges

**Next evolution**: Run /reflect to accumulate more data, then /evolve again.
```

## Skill + Tricks Combination Model

The key insight: **a skill is a base technique + accumulated context-specific tricks**.

```
┌─────────────────────────────────────────┐
│            api_development              │
│                                         │
│  Base Technique:                        │
│    REST API design with proper          │
│    routing, validation, error handling  │
│                                         │
│  Tricks (accumulated over time):        │
│    ├─ "Zod-first schemas" (TS APIs)     │
│    ├─ "Middleware ordering" (Express)    │
│    ├─ "OpenAPI spec first" (team APIs)  │
│    └─ ... (grows with each /reflect)    │
│                                         │
│  When selected, agent gets:             │
│    base technique + relevant tricks     │
│    matched by current context           │
└─────────────────────────────────────────┘
```

Over time, skills become more capable because they accumulate tricks from
diverse usage contexts. A skill used 20 times across different projects will
have a rich tricks library that a brand-new skill won't.

## Archive Structure

```
~/.claude/skills/_archived/
├── {skill_id}.yaml           # Archived skill file
└── archive_manifest.yaml     # When archived, why, can resurrect?
```

## What This Skill Does NOT Do

- Does not read the worklog (that's `/reflect`)
- Does not run during normal work (only on explicit invocation)
- Does not auto-promote without user awareness (always reports what changed)
- Does not delete skills permanently (archives them for possible resurrection)
