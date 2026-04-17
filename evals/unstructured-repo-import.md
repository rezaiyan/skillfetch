# Scenario 08 — Unstructured / Personal Repo

## Input
```
/skillfetch add-repo https://github.com/affaan-m/everything-claude-code
```
Precondition: repo has no `skills-manifest.json`, README does not list skill paths,
but has `.md` files scattered across the tree (SKILL.md, docs/, etc.).

## Expected

1. Standard mode detection fails (no manifest, no structured README).
2. GitHub file tree is fetched via `api.github.com` — no sub-agents used.
3. `.md` candidates are quality-scored.
4. Unstructured warning is shown:
   ```
   ⚠  Non-standard repo detected
   ```
5. Candidate list is shown with quality labels (`high` / `medium` / `low`).
6. Low-quality files (README, changelogs) are excluded from the menu or marked clearly.
7. User is prompted for each candidate: `[I]mport as-is`, `[R]eformat`, `[S]kip`.
8. Selecting `R` → Claude rewrites the file into a structured SKILL.md without inventing content.
9. Security scan runs on the **rewritten** output.
10. File written to `synced/<alias>/` only after scan passes.
11. `registry.json` entry includes `"reformatted": true` and `"original_url"`.

## Result
<!-- fill in after running -->
pass / fail — notes:
