# Manage Commands

Full workflows for: `add-repo`, `add-skill`, `remove-skill`, `remove-repo`.

Do NOT spawn sub-agents at any step — use WebFetch and Read tools directly so menus
appear in the current conversation and the user can type their selection.

> **Path and naming authority:** All alias derivation, skill-name derivation, directory
> creation/cleanup, and path validation rules live in [directories.md](directories.md).
> This file defers to it entirely for those decisions.

---

## `add-repo <url>` — Discover and Selectively Register a Repo

Never registers everything — always shows a menu first.

### Step 1 — Derive basics

Infer from the GitHub URL, ask only if ambiguous.
- `alias` — derived from the repo name following the algorithm in [directories.md](directories.md)
- `api_base` — `https://api.github.com/repos/{owner}/{repo}`
- `branch` — default `main`; if the user provides a branch via `add-repo <url> --branch <name>`,
  use that instead. If `main` returns 404 for the first fetch, try `master` and prompt
  the user to confirm the branch before proceeding.
- `raw_base` — `https://raw.githubusercontent.com/{owner}/{repo}/{branch}`
- Validate domain is `raw.githubusercontent.com` or `api.github.com`.
  Unknown domain → WARN and require confirmation before continuing.

### Step 2 — Detect repo format

Try in order, stopping as soon as one succeeds:

**a) Structured manifest**
Fetch `{raw_base}/skills-manifest.json` (resource guard: refuse if > 50 KB).
If found and valid JSON with a `skills` array → **Standard Mode**, go to Step 3A.

**b) Structured README**
Fetch `{raw_base}/README.md` (resource guard: truncate at 100 KB).
If the README lists skill paths (lines matching `*/SKILL.md` or a skills table) → **Standard Mode**, go to Step 3A.

**c) GitHub file tree**
Fetch `{api_base}/git/trees/HEAD?recursive=1` via WebFetch.
Resource guard: if response > 200 KB or contains > 2 000 files, stop tree traversal —
extract only the first 2 000 paths and note truncation.
Filter paths to `.md` files only. Go to Step 3B (Unstructured Mode).

**d) Probe common paths**
If the tree fetch also fails, try these paths one by one via WebFetch:
```
SKILL.md
.claude/SKILL.md
.claude/skills/SKILL.md
claude/SKILL.md
skills/SKILL.md
docs/SKILL.md
```
If any exist → Unstructured Mode with those candidates.
If none exist → report "No skill files found in this repo" and stop.

---

### Step 3A — Standard Mode (structured repo)

Present the numbered menu and wait for user reply:

```
Available skills in <owner>/<repo>:
─────────────────────────────────────────────────────────
 1. code-review              workflows/code-review/SKILL.md
    Structured code review checklist and comment templates
 2. ci-setup                 workflows/ci-setup/SKILL.md
    Configure CI pipelines: lint, test, build, deploy stages
─────────────────────────────────────────────────────────
Enter numbers to add (e.g. "1 3"), or "all":
```

Apply resource guards from SKILL.md (batch of 5, confirm before >5).
Register only selected skills. Immediately sync each one. Report results.

---

### Step 3B — Unstructured Mode (personal / non-standard repo)

#### Quality scoring

Before showing anything to the user, fetch each candidate `.md` file (resource guard:
skip files > 300 KB / 1 500 lines) and score it across three dimensions:

**A — File naming & location (Claude Code conventions)**

| Signal | Score |
|--------|-------|
| File is named exactly `SKILL.md` | +3 |
| File lives in `.claude/skills/*/` | +2 |
| File lives in `.claude/` | +1 |
| File lives in `skills/` or `claude/` at root | +1 |
| File is named `skill.md` (wrong case) | +0 |
| File has a generic name (`notes.md`, `guide.md`, `tips.md`) | −1 |
| File is named `README.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md` | −3 |

**B — File length (Claude Code best practices: 50–500 lines ideal)**

| Length | Score |
|--------|-------|
| 50–500 lines | +2 |
| 500–800 lines | +1 |
| 30–49 lines | +0 |
| > 800 lines | −1 (also triggers suspicion score +1 in security scanner) |
| < 30 lines | −2 |
| < 10 lines | −3 |

**C — Content quality**

| Signal | Score |
|--------|-------|
| Has valid SKILL.md frontmatter (`name:`, `description:`, `when_to_use:`) | +4 |
| Has `## Steps`, `## Workflow`, or a numbered list | +2 |
| Contains fenced code blocks | +2 |
| References domain-specific APIs, frameworks, or tools by name (e.g. library names, CLI commands, config keys) | +2 |
| Has a clear task-focused title (h1 or h2) | +1 |
| Has explicit "when to use" or trigger description | +1 |
| Looks like a changelog, license, or contributing guide | −3 |
| Looks like a README describing the repo itself | −2 |

**Total score classification:**
- **Score ≥ 6** → `high` — well-structured, likely usable as-is
- **Score 3–5** → `medium` — has useful content but needs cleanup
- **Score 1–2** → `low` — thin or off-topic; suggest skip or generate
- **Score ≤ 0** → excluded from menu unless it's the only candidate

**Compliance label** — also show whether the file follows the official Claude Code SKILL.md spec:
- `spec-compliant` — has valid frontmatter (`name`, `description`, `when_to_use`) + body sections
- `spec-partial` — has some frontmatter or sections but not complete
- `non-standard` — no frontmatter, free-form content

#### Unstructured warning + candidate menu

Show the warning, then the scored candidates, then stop and wait for user reply:

```
⚠  Non-standard repo detected
   No skills-manifest.json found. README does not list skill paths.
   Scanned file tree — found N .md file(s). Showing candidates below.

Candidates in affaan-m/everything-claude-code:
──────────────────────────────────────────────────────────────────────
 1. .claude/skills/SKILL.md             quality: high  spec: partial
    84 lines · "Claude Code workflow patterns — hooks, skills, prompts"

 2. docs/patterns.md                   quality: medium  spec: non-standard
    210 lines · "Prompt patterns — structured output, context management"

 3. README.md                             quality: low  spec: non-standard
    31 lines · General repo description — not actionable as a skill.
    (excluded — score 0)
──────────────────────────────────────────────────────────────────────
Import mode for each candidate:
  [I] Import as-is   — security-scan and copy raw content
  [R] Reformat       — Claude restructures into a clean SKILL.md body
  [G] Generate       — Claude generates a proper spec-compliant SKILL.md
                       with full frontmatter, following the official
                       Claude Code / agentskills.io open standard
  [S] Skip

Enter: e.g. "1G 2R" or "all G":
```

#### Import modes

**[I] Import as-is**
Security-scan the raw content (see `../security.md`). If it passes, write it unchanged
to `synced/<alias>/<name>/SKILL.md`. Register with `"method": "imported"`.
Recommended only for `spec-compliant` files that scored `high`.

**[R] Reformat**
Read the file, restructure it into a clean SKILL.md body (no frontmatter added).
Preserves all technical content; removes noise (repo promotion, meta-commentary).
Security-scan the **rewritten** output before writing.
Register with `"method": "reformatted"`.

Rules:
- Keep ALL technical content — commands, APIs, code examples, version numbers
- Remove: "star this repo", badges, changelogs mixed into content
- Do NOT invent content — only restructure what exists
- Do NOT collapse detail — if a step has sub-steps, keep them

**[G] Generate (recommended for non-standard and medium-quality files)**
Read the source content, then generate a fully spec-compliant SKILL.md following the
official [agentskills.io open standard](https://agentskills.io) and Claude Code conventions:

```markdown
---
name: <kebab-case-task-name>
description: <third-person, front-loaded, ≤ 160 chars. What it does + when to trigger>
version: 1.0.0
when_to_use: |
  <Trigger phrases and conditions. Be specific — vague descriptions cause the skill
  to be ignored or over-triggered.>
---

# <Task Name>

**Source:** <original URL>
**Generated:** <date> (content from original, structure from Claude Code spec)

## Overview
<One paragraph: what this skill does and why it's useful>

## When to Use
<Bulleted trigger conditions, copied/derived from source>

## Steps
<Numbered, actionable steps. Each step is a single clear action.>

## Key APIs and Commands
<Code blocks with the most important snippets from the source>

## Pitfalls
<Common mistakes or gotchas extracted from the source>

## References
- Source: <original URL>

<!-- LOCAL ADDITIONS START -->
<!-- LOCAL ADDITIONS END -->
```

Rules for Generate:
- `name` field: kebab-case, describes the task not the repo (e.g. `ci-pipeline-setup` not `my-repo-skill`)
- `description` field: third person, front-load the key use case, ≤ 160 characters
- `when_to_use` field: specific trigger phrases — what the user would type that should invoke this
- Preserve ALL technical detail from the source — commands, API names, version numbers, code examples
- Do NOT invent steps or APIs not in the source
- Security-scan the **generated** output before writing
- Register with `"method": "generated"`, `"original_url"`, `"spec_version": "agentskills.io/1.0"`

**[S] Skip**
Do not write or register anything for this candidate.

---

#### Genericity Check (applies after every I / R / G)

After generating, reformatting, or importing a skill, evaluate whether it is **too generic**
before writing to disk. A skill is too generic if it meets **two or more** of these signals:

| Signal | Example |
|--------|---------|
| `when_to_use` lists 6+ trigger conditions spanning different domains | "create a project", "add a module", "configure CI", "write tests", "manage deps", "write docs" |
| Content has 4+ major sections covering unrelated concerns | Architecture + Testing + Deployment + Monitoring in one file |
| `name` or `description` describes a whole platform/ecosystem | "python-development", "web-frontend", "mobile-app" |
| Source file is clearly an index linking to sub-files | Table of contents with `[topic](references/topic.md)` links |
| Skill would trigger on almost any task in the tech domain | Too broad to have a clear single trigger |

If two or more signals are present, **pause and show this prompt before writing anything:**

```
⚠  This skill may be too generic to be useful.

   Name:    <proposed-name>
   Signals: <list the matched signals>

   A generic skill is hard to trigger precisely and competes with more focused ones.

   Options:
     [K] Keep as-is        — write the skill as generated (not recommended)
     [S] Split into parts  — I'll propose focused sub-skills based on the source content
     [F] Focus it          — rewrite to cover only one specific concern (you choose which)
     [X] Abort             — discard this candidate entirely

   Enter choice:
```

**[K] Keep as-is**
Proceed with writing the skill unchanged. Register normally.

**[S] Split into parts**
Analyse the source content and propose 2–5 focused sub-skills, each covering one concern.
Show a numbered list with proposed `name`, one-line description, and which sections of the
source would go into it. Wait for the developer to confirm the split before writing anything.
Each sub-skill goes through its own security scan, genericity check, and registration.

**[F] Focus it**
Ask: `"Which concern should this skill focus on? (e.g. setup workflow, testing patterns, deployment steps)"`
Wait for reply, then rewrite the skill to cover only that concern — drop all other sections.
Re-run security scan and genericity check on the focused output before writing.

**[X] Abort**
Discard this candidate. Do not write or register anything.

---

#### Companion Files Detection (applies to all import modes)

After writing any skill file ([I], [R], or [G]), scan the **written content** for links
pointing to other `.md` files inside the same repo (`raw_base`). These appear as:

- Absolute URLs: `https://raw.githubusercontent.com/{owner}/{repo}/.../*.md`
- Relative markdown links: `[label](path/to/file.md)` where the path is within the repo
- A `## References` / `## See also` section listing `{raw_base}/...` paths

**Detection algorithm:**
1. Collect all URLs/paths in the written file that resolve to `{raw_base}/*.md`.
2. Exclude the file itself and any already-registered `remote_path` values.
3. Fetch each candidate (resource guard: skip if > 300 KB / 1 500 lines) and apply
   quality scoring (same three-dimension algorithm as Step 3B).
4. If any candidates score `medium` or higher, show the companion menu:

```
📎 Companion files detected in <alias>
   The skill you just added links to N other .md files in this repo.
   These may contain additional useful content.

──────────────────────────────────────────────────────────────────────
 1. references/architecture.md        quality: high  spec: non-standard
    142 lines · "System design patterns — service boundaries, data flow"

 2. references/testing-strategy.md    quality: medium  spec: non-standard
    98 lines · "Test pyramid, integration testing, mocking strategies"

 3. references/release-notes.md       quality: low  spec: non-standard
    22 lines · Release version history
    (excluded — score 1)
──────────────────────────────────────────────────────────────────────
Add companions? Enter numbers (e.g. "1 2"), "all", or "skip":
```

5. Apply the same batch limit (5 per operation) and "all" safeguard from Resource Guards.
6. For each selected companion: show the [I]/[R]/[G]/[S] menu, run security scan, write,
   and register. Same flow as Step 3B — no special-casing.
7. If no companions score `medium` or higher → silently skip (do not show the menu).
8. Companions discovered this way get `"discovered_from": "<parent-skill-name>"` in
   their registry entry for traceability.

**Why this matters:** Skills that act as an index (root SKILL.md linking to sub-files)
silently discard most of their content if companions are ignored. This step surfaces that
content without forcing the user to know the repo's internal layout in advance.

---

#### Low-quality-only result

If all candidates scored `low` / excluded and no `high`/`medium` files found:
```
⚠  No useful skill files found in this repo.
   All .md files appear to be documentation, changelogs, or repo descriptions
   rather than actionable AI instructions.

   Recommendation: This repo is probably not worth adding.

   Options:
     [F] Force-add — provide a file path manually, then choose I / R / G
     [A] Abort
```

---

## `add-skill <alias>` — Add More Skills from an Existing Repo

For repos already in `registry.json`.

1. Read `raw_base`, `api_base`, and the existing `skills` map from the repo entry.
2. Collect already-registered `remote_path` values.
3. Re-run discovery (Step 2 of `add-repo`) to find all available skills.
4. **Filter by `remote_path`** — a skill is already registered if its remote path exists
   in the skills map. Local alias mismatches don't matter.
5. Show only unregistered candidates. If all are registered → "All available skills are
   already registered." and stop.
6. For unstructured repos, apply quality scoring and show the [I]/[R]/[G]/[S] menu.
7. Add selected skills to `registry.json`. Sync immediately. No sub-agents.
8. Run Companion Files Detection on each written skill (same rules as Step 3B above).

---

## `remove-skill <alias> [skill-name | all]` — Remove Registered Skills

Does not remove the repo entry — use `remove-repo` for that.

1. **Show what will be removed** with local additions warning:

   ```
   Removing from my-skills:
   ──────────────────────────────────────────────────────────
    • code-review    synced/my-skills/code-review/SKILL.md
                     ⚠ contains local additions (3 lines)
    • ci-setup       synced/my-skills/ci-setup/SKILL.md
                     no local additions
   ──────────────────────────────────────────────────────────
   This will delete the local files and remove them from registry.json.
   Proceed? [Y/n]
   ```

2. Wait for explicit `Y` before deleting anything.
3. Delete the local file(s) — only inside `synced/`.
   If the skill directory is empty after removal, delete it too.
4. Remove skill entries from `registry.json`.
   If `all` used and all skills removed, leave the repo entry with an empty `skills` map.
5. Confirm what was removed.

---

## `remove-repo <alias>` — Deregister a Repository

1. Show a single confirmation prompt listing everything that will be deleted — registry
   entry and all local skill files together. Do not split into multiple questions.

   ```
   Removing repo <alias>:
   ──────────────────────────────────────────────────────────
    • registry entry removed
    • synced/<alias>/code-review/SKILL.md   ⚠ contains local additions (3 lines)
    • synced/<alias>/ci-setup/SKILL.md      no local additions
   ──────────────────────────────────────────────────────────
   This will remove the registry entry AND delete all local files. Proceed? [Y/n]
   ```

2. Wait for `Y`. On `Y`: delete all files in `synced/<alias>/` and the directory itself,
   then remove the repo entry from `registry.json` in one operation.
3. Confirm what was removed.

---

## Expanding to New Repos

Each new repo gets `synced/<alias>/` and its own block in `registry.json`.
Skills not selected are never written to disk.

Example `registry.json` entry for a reformatted skill from a personal repo:

```json
"everything-claude-code": {
  "name": "Everything Claude Code",
  "url": "https://github.com/affaan-m/everything-claude-code",
  "branch": "main",
  "raw_base": "https://raw.githubusercontent.com/affaan-m/everything-claude-code/main",
  "trusted_source": false,
  "last_synced": "2026-04-17",
  "skills": {
    "claude-code-patterns": {
      "description": "Claude Code best practices — prompts, workflows, and skill authoring",
      "remote_path": "SKILL.md",
      "local_path": "synced/everything-claude-code/claude-code-patterns/SKILL.md",
      "reformatted": true,
      "original_url": "https://raw.githubusercontent.com/affaan-m/everything-claude-code/main/SKILL.md",
      "last_synced": "2026-04-17"
    }
  }
}
```
