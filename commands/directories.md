# Directory Management

All rules for how directories and file paths are created, named, validated, and cleaned up
within this skill. Every other command file defers to this one for path and naming decisions.

---

## Root Base Path

All paths managed by this skill are rooted at:
```
.claude/skills/skillfetch/
```

This is the **base path**. Every `local_path` value in `registry.json` is relative to it.
Always resolve to the full path before reading or writing:
```
.claude/skills/skillfetch/<local_path>
```

Never read or write outside this base path. Attempting to do so is a BLOCK-level violation.

---

## Layout Contract

```
<base>/
  SKILL.md              ← skill definition (never written by commands)
  registry.json         ← registry (written only by add/remove commands)
  security.md           ← security rules (never written by commands)
  commands/             ← command definitions (never written by commands)
  evals/                ← test scenarios (never written by commands)
  synced/               ← ALL fetched content lives here, nowhere else
    <repo-alias>/
      <skill-name>/
        SKILL.md        ← one file per skill, always named SKILL.md
```

**Depth is fixed at exactly 3 levels under `synced/`:**
`synced` → `<repo-alias>` → `<skill-name>` → `SKILL.md`

No nesting deeper than this. No files directly in `synced/` or directly in `synced/<alias>/`.

---

## Alias Naming Rules (repo-level directory)

The `alias` is the directory name under `synced/` for a repo. Derived automatically from
the repo URL — never taken verbatim from remote content.

### Derivation algorithm

Given a GitHub URL `https://github.com/{owner}/{repo}`:

1. Take the `{repo}` segment only (ignore owner).
2. Lowercase everything.
3. Replace any non-alphanumeric character (spaces, underscores, dots, slashes) with `-`.
4. Collapse consecutive `-` into one.
5. Strip leading and trailing `-`.
6. Truncate to 40 characters maximum.

Examples of the algorithm (no third-party names embedded as rules):
```
"my_android_skills"  →  "my-android-skills"
"Claude.AI-Helpers"  →  "claude-ai-helpers"
"skills.v2"          →  "skills-v2"
"--odd--repo--"      →  "odd-repo"
```

### Collision handling

If the derived alias already exists in `registry.json`:
1. Show: `"Alias '<derived>' is already taken by <existing-url>."`
2. Suggest: `"<derived>-2"` (or `-3`, `-4` incrementally).
3. Ask developer to confirm the suggested alias or provide their own.
4. Never silently overwrite an existing alias.

### Reserved names

These aliases are forbidden — they conflict with the skill's own structure:

```
commands  security  evals  synced  registry  skill
```

If the derived alias matches a reserved name, append `-repo` to it:
`commands` → `commands-repo`.

---

## Skill-Name Naming Rules (skill-level directory)

The `skill-name` is the directory under `synced/<alias>/`. Derived from the remote file path.

### Derivation algorithm

Given a `remote_path` such as `workflows/code-review/SKILL.md`:

1. Take the **parent directory name** of the file (the leaf directory before the filename).
   `workflows/code-review/SKILL.md` → `code-review`
2. Apply the same lowercase + kebab-case normalisation as alias derivation above.
3. Truncate to 40 characters maximum.

For files at the repo root (e.g. `SKILL.md` with no parent directory):
- Use the alias as the skill-name.
- If that would create a collision, use `<alias>-skill`.

For generated or reformatted skills where the remote path is ambiguous:
- Derive from the skill's `name` frontmatter field if present.
- Otherwise derive from the first h1 heading of the file.
- Fall back to `<alias>-<index>` (e.g. `my-repo-1`).

### Collision handling within a repo

If a skill-name already exists under the alias:
1. Show: `"Skill directory '<name>' already exists under '<alias>'."`
2. Options: `[O]verwrite (re-sync), [R]ename to '<name>-2', [A]bort`
3. Wait for developer choice.

---

## File Naming

Every synced skill file is always named **`SKILL.md`** — exactly, case-sensitive.
No other filename is valid. The only exception is the local additions content, which is
embedded inside `SKILL.md` between the markers, not in a separate file.

---

## Directory Creation Rules

When creating directories:
1. Only create inside `synced/`.
2. Create `synced/<alias>/` if it does not exist.
3. Create `synced/<alias>/<skill-name>/` if it does not exist.
4. Never create directories for skills that have not passed the security scan.
5. Never create directories pre-emptively — only when writing a skill file.

---

## Directory Cleanup Rules

When removing skills:
1. Delete `synced/<alias>/<skill-name>/SKILL.md`.
2. If `synced/<alias>/<skill-name>/` is now empty → delete the directory.
3. If `synced/<alias>/` is now empty → delete it too.
4. Never delete `synced/` itself.
5. Never delete anything outside `synced/`.

When removing a repo (`remove-repo`):
- Ask whether to delete `synced/<alias>/` entirely or keep cached files.
- If developer chooses delete: remove the whole directory tree under `synced/<alias>/`.
- The repo entry is removed from `registry.json` regardless of whether files are kept.

---

## Path Validation

Before any read or write, validate the resolved path:

```
VALID:   .claude/skills/skillfetch/synced/<alias>/<skill>/SKILL.md
INVALID: .claude/skills/skillfetch/SKILL.md          ← skill's own file
INVALID: .claude/skills/skillfetch/registry.json     ← registry (use dedicated logic)
INVALID: .claude/skills/skillfetch/commands/...      ← command definitions
INVALID: .claude/skills/skillfetch/security.md       ← security rules
INVALID: .claude/CLAUDE.md                                 ← project config
INVALID: anything with ../                                 ← path traversal
INVALID: anything outside .claude/skills/skillfetch/ ← out of scope
```

If a computed path fails validation → abort the operation and report the violation.
Path traversal attempts (`../`, `%2e%2e`, URL-encoded sequences) are treated as
BLOCK-level security violations.

---

## Registry Path Contract

`local_path` values stored in `registry.json` must:
- Be relative (no leading `/` or `./`)
- Start with `synced/`
- Contain exactly two directory segments after `synced/` before the filename
- End with `/SKILL.md`

Valid: `synced/my-repo/my-skill/SKILL.md`
Invalid: `synced/my-skill/SKILL.md` (missing alias level)
Invalid: `synced/my-repo/sub/my-skill/SKILL.md` (too deep)
Invalid: `/absolute/path/SKILL.md` (absolute)

Reject and report any `local_path` that does not conform before reading or writing.
