# skillfetch

A Claude Code plugin for safely pulling AI skill instructions from external GitHub repositories.

Register repos, pick which skills to sync, preview diffs before writing, keep project-specific notes that survive updates — with a security scanner blocking prompt injection at every step.

---

## What It Does

Claude Code works best with domain-specific context loaded as skills. Projects like [android/skills](https://github.com/android/skills) and [everything-claude-code](https://github.com/affaan-m/everything-claude-code) publish maintained `SKILL.md` files that teach the assistant how to handle specific tasks — across any tech stack or domain.

This plugin gives you a structured workflow to manage them:

- **Add** a repo → see a numbered menu of available skills → pick what you want
- **Sync** registered skills → see a diff → decide before writing
- **Keep local notes** in synced files that survive future syncs
- **Security scanner** blocks prompt injection, credential harvesting, and self-modification before anything hits disk
- **Works with any repo** — structured manifests, standard READMEs, or raw file trees

---

## Install

```bash
# 1. Clone the plugin (choose any location)
git clone https://github.com/rezaiyan/skillfetch ~/tools/skillfetch

# 2. Run the install script (from inside your project directory)
cd /path/to/your/project
~/tools/skillfetch/install.sh
```

The script:
- Symlinks instruction files from the plugin into `.claude/skills/skillfetch/`
- Creates a fresh `registry.json` from the template
- Creates the `synced/` directory

**No CLAUDE.md changes needed** — Claude Code auto-loads skills from `.claude/skills/`.

### Updating

```bash
cd ~/tools/skillfetch
git pull
# Re-run install to refresh symlinks (safe to run multiple times)
~/tools/skillfetch/install.sh /path/to/your/project
```

### What to commit to your project

The symlinks are machine-local (they point to your local plugin clone) — don't commit them.
Commit only the project data:

```
# Add to your project's .gitignore:
.claude/skills/skillfetch/SKILL.md
.claude/skills/skillfetch/security.md
.claude/skills/skillfetch/commands/
.claude/skills/skillfetch/evals/
```

Keep and commit:
- `.claude/skills/skillfetch/registry.json` — your registered repos and skills
- `.claude/skills/skillfetch/synced/` — the synced skill files (optional but recommended)

---

## Usage

All commands run via `/skillfetch <command>` in Claude Code.

```
/skillfetch help
/skillfetch list
/skillfetch add-repo https://github.com/android/skills
 /skillfetch add-repo https://github.com/affaan-m/everything-claude-code
/skillfetch sync android-skills
/skillfetch sync android-skills edge-to-edge
/skillfetch sync everything-claude-code skill-authoring
/skillfetch sync all
/skillfetch add-skill android-skills
/skillfetch remove-skill android-skills edge-to-edge
/skillfetch remove-repo android-skills
```

### First-time setup

```
/skillfetch add-repo https://github.com/android/skills
# → shows numbered menu of available skills
# → enter "1 3 5" to pick, or "all"
# → selected skills are security-scanned and written to synced/

/skillfetch add-repo https://github.com/affaan-m/everything-claude-code
# → same flow for Claude Code workflow skills
```

### Keeping skills up to date

```
/skillfetch sync android-skills
# → fetches each registered skill
# → shows diff for any that changed
# → asks before writing
```

### Checking what's registered

```
/skillfetch list

REPO                    SKILL                     LAST SYNCED     STATUS
android-skills          edge-to-edge              2026-04-17      ok
everything-claude-code  skill-authoring           2026-04-17      ok
```

---

## Local Annotations

Add project-specific notes to any synced file without losing them on the next sync:

```markdown
<!-- LOCAL ADDITIONS START -->
## Project Notes
We enforce stricter lint rules — always run with `--max-warnings 0`.
<!-- LOCAL ADDITIONS END -->
```

On the next sync, you get the choice:
```
[O] Override  — replace entirely with remote version (additions lost)
[M] Merge     — apply remote update, keep your additions at the bottom
[S] Skip      — leave this file unchanged
```

---

## Security Model

Every remote file is scanned **before** being written to disk:

| Tier | Trigger | Action |
|------|---------|--------|
| **BLOCK** | Prompt injection, code execution, credential harvesting, self-modification instructions | Abort — no override possible |
| **WARN** | AI system references used instructionally, scope creep, suspicious URLs | Pause — show flags + require explicit YES |
| **Score ≥ 3** | Cumulative soft flags (large file, external links, `.claude/` references) | Treated as WARN |

Details: [`security.md`](security.md)

---

## File Layout

```
.claude/skills/skillfetch/     ← install location in your project
  SKILL.md        → symlink to plugin
  security.md     → symlink to plugin
  commands/       → symlink to plugin
  evals/          → symlink to plugin
  registry.json   ← project-local (committed)
  synced/         ← project-local (committed)
    <repo-alias>/
      <skill-name>/
        SKILL.md
```

Plugin source (single machine-local copy, shared across all your projects):
```
~/tools/skillfetch/    ← or wherever you cloned it
  SKILL.md
  security.md
  commands/
    sync.md
    manage.md
    directories.md
  evals/
    README.md
    scenario-*.md
  registry.template.json
  install.sh
```

---

## Evals

The `evals/` directory contains test scenarios for validating the skill behaviour.
Run them in a fresh Claude Code session (no prior context) to verify commands work as documented.

---

## No Sub-Agents

**Every command runs directly in the current conversation.** No Agent tool, no background workers.

This is intentional: commands show interactive menus, wait for user input, and display diffs in real time. Sub-agents run headlessly and can't do any of that. They also burn ~16k tokens per call.
