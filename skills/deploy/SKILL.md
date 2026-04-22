---
name: deploy
description: This skill should be used when the user wants to release, publish, bump the version, tag, or deploy the skillfetch plugin.
version: 1.0.0
---

# Deploy — skillfetch Release Workflow

Full release process: validate → bump versions → commit → tag → push.

## Usage

```
/deploy patch      # 1.0.0 → 1.0.1
/deploy minor      # 1.0.0 → 1.1.0
/deploy major      # 1.0.0 → 2.0.0
/deploy v1.2.3     # explicit version
```

## Steps

### 1. Read current version

Read current version from `.claude-plugin/plugin.json` (the `"version"` field).
This is the sole authoritative version — plugin is distributed via GitHub source so plugin.json wins.

### 2. Calculate new version

Apply the bump type to the current semver, or use the explicit version provided.
If no argument given, ask: `"Bump type? [patch / minor / major / vX.Y.Z]"` and wait.

Show the version change before proceeding:
```
Current version : 1.0.0
New version     : 1.0.1
```

### 3. Validate plugin

Run validation before touching any files:
```bash
claude plugin validate .
```

If validation fails → stop, show the errors, do not proceed.

### 4. Confirm release plan

Show the full plan and ask `"Proceed with release? [Y/n]"` — wait for explicit `Y` before doing anything.

```
Release plan for v1.0.1:
  • Bump version in .claude-plugin/plugin.json
  • Bump version in skills/skillfetch/SKILL.md (frontmatter)
  • git add -A
  • git commit -m "chore: release v1.0.1"
  • git tag v1.0.1 -m "Release v1.0.1"
  • git push origin main --tags
```

### 5. Bump versions

Update the version field in exactly two files:

**`.claude-plugin/plugin.json`** — `"version"` field.

**`skills/skillfetch/SKILL.md`** — `version:` line in the YAML frontmatter block.

### 6. Stage and commit

```bash
git add -A
git commit -m "chore: release vNEW_VERSION"
```

### 7. Tag

```bash
git tag vNEW_VERSION -m "Release vNEW_VERSION"
```

### 8. Push

```bash
git push origin main --tags
```

### 9. Report

```
Released v1.0.1
  commit  abc1234
  tag     v1.0.1
  pushed  origin/main

Users update with:
  /plugin marketplace update rezaiyan
```

## Error Handling

| Failure point | Action |
|--------------|--------|
| Validation fails (step 3) | Stop — show errors, nothing written |
| User says N at confirmation (step 4) | Stop — nothing done |
| Version files fail to update | Stop before git operations |
| `git push` fails | Report the error — commit and tag already exist locally, user can push manually |
