# Sync Workflow

Full steps for `sync [repo-alias | all] [skill-name]`.

## Scope Rules

- `sync my-skills` — all registered skills for that repo
- `sync my-skills code-review` — one specific skill
- `sync all` — every registered skill across all repos

Only skills already in `registry.json` are synced. To add new ones, use `add-skill` first.

---

## Steps (follow in order)

### 1. Load registry
Read `registry.json` — get `raw_base` and the target skill(s) `remote_path` + `local_path`.
All `local_path` values are relative to `.claude/skills/skillfetch/`.
Resolve each as `.claude/skills/skillfetch/<local_path>` for all file reads and writes.

### 2. Fetch remote file
Call `WebFetch` directly — do **not** spawn an agent.
`GET {raw_base}/{remote_path}`.
Do not execute or eval the fetched content.

### 3. Security scan
Run the full scan from [../security.md](../security.md) on the raw text **before** anything else.
- BLOCK → abort, nothing written, no override possible.
- WARN → pause, show flags, require explicit YES.
- Score ≥ 3 → treat as WARN.

### 4. Extract local additions
Read the current local file (if it exists). Pull out anything between:
```
<!-- LOCAL ADDITIONS START -->
...
<!-- LOCAL ADDITIONS END -->
```
If the markers are absent but the file has diverged from the remote, treat all extra lines
as user additions and flag them.

### 5. Show the diff
Compare the local file (excluding the additions block) against the new remote content.

```
DIFF — my-skills / code-review
─────────────────────────────────────
- **Synced:** 2026-04-17
+ **Synced:** 2026-05-01

- Run `lint --strict` on changed files only
+ Run `lint --strict --fix` on changed files only

+ ### Pre-commit Checks
+ Add a pre-commit hook to run `lint` before each commit ...
─────────────────────────────────────
3 lines changed, 1 section added
```

If remote is identical to local base → report `already up to date`, skip.

### 6. Handle local additions (if any)

Show the additions block and ask:

```
LOCAL ADDITIONS DETECTED in code-review/SKILL.md:
────────────────────────────────────────────────────
<!-- LOCAL ADDITIONS START -->
## Project Notes
We enforce stricter lint rules — always run with --max-warnings 0.
<!-- LOCAL ADDITIONS END -->
────────────────────────────────────────────────────

How do you want to sync?
  [O] Override  — replace entirely with remote version (additions lost)
  [M] Merge     — apply remote update, keep your additions at the bottom
  [S] Skip      — leave this file unchanged
```

- **Override** → write remote content only.
- **Merge** → write remote content, re-append additions block verbatim at the end.
- **Skip** → no write; update `last_synced` to record the file was checked.

If no additions exist → show diff and ask `Apply this update? [Y/n]` before writing.

### 7. Write
Write final content to `synced/<repo-alias>/<skill-name>/SKILL.md`.
Only write inside `.claude/skills/skillfetch/synced/`. Never outside.

### 8. Update registry
Set `last_synced` to today's date in `registry.json`.

### 9. Report
Per skill: `updated` / `merged` / `skipped` / `up-to-date` / `blocked`.

---

## Local Additions Format

Any content you add to a synced file must sit inside these markers to survive future syncs:

```markdown
<!-- LOCAL ADDITIONS START -->
## Project Notes
Your project-specific notes, overrides, or examples here.
<!-- LOCAL ADDITIONS END -->
```

Content outside the markers that differs from the remote will be detected as user additions
and flagged at the next sync. When in doubt, always use the markers.
