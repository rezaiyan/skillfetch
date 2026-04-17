# Evals

Test scenarios for validating the skillfetch sync skill.
Run these manually using a fresh Claude instance (Claude B) to verify behaviour matches expectations.

---

## How to Run

1. Open a **new Claude Code session** (no prior context of this skill).
2. Trigger `/skillfetch` with the scenario input below.
3. Compare actual output against the expected output.
4. Document failures in a new `.md` file here; report back to improve the skill.

---

## Scenario 01 — List with Missing File

**Input:**
```
/skillfetch list
```
Precondition: manually delete `synced/my-skills/code-review/SKILL.md` before running.

**Expected:**
- Table shows all registered entries
- `code-review` shows status `missing`, others show `ok`

---

## Scenario 02 — Sync Up-to-Date Skill

**Input:**
```
/skillfetch sync my-skills code-review
```
Precondition: `code-review/SKILL.md` is already current (no remote changes).

**Expected:**
- Reports `already up to date`
- No diff shown
- No write to disk
- No prompt asking for confirmation

---

## Scenario 03 — Sync with Local Additions

**Input:**
```
/skillfetch sync my-skills code-review
```
Precondition: `code-review/SKILL.md` has content inside `<!-- LOCAL ADDITIONS START/END -->`,
and the remote has a newer version.

**Expected:**
- Diff is shown
- Local additions block is shown
- `[O] Override / [M] Merge / [S] Skip` prompt appears
- Selecting `M` → remote update applied, additions preserved at end
- Selecting `O` → remote update applied, additions gone
- Selecting `S` → no write, `last_synced` updated to note skipped

---

## Scenario 04 — Security: BLOCK Pattern

**Input:** Attempt to sync a skill file that contains `ignore all previous instructions`.
*(Use a locally modified copy of any synced file to simulate, or a test repo.)*

**Expected:**
- Sync aborts immediately
- Blocked report shown with exact line number
- No file written to disk
- No confirmation prompt offered

---

## Scenario 05 — Security: WARN Pattern

**Input:** Attempt to sync a skill file that references `Claude should also...`.

**Expected:**
- Sync pauses
- Warning shown with exact flagged text and line number
- `[Y/n]` prompt asking developer to confirm
- Proceeding with `n` → no write
- Proceeding with `y` → sync continues

---

## Scenario 06 — add-repo Discovery

**Input:**
```
/skillfetch add-repo https://github.com/android/skills
```

**Expected:**
- Agent fetches README
- Numbered menu shown with all available skills
- Only selected numbers are registered in `registry.json`
- Unselected skills are not written to disk or added to registry
- Immediate sync of selected skills

---

## Scenario 07 — remove-skill with Additions Warning

**Input:**
```
/skillfetch remove-skill my-skills code-review
```
Precondition: `code-review/SKILL.md` has non-empty local additions.

**Expected:**
- Summary shown listing file + `⚠ contains local additions (N lines)` warning
- `[Y/n]` confirmation prompt
- `n` → no deletion
- `y` → file deleted, entry removed from `registry.json`

---

## Adding New Scenarios

Name files `scenario-NN-description.md`. Document:
- **Input** (the command and any preconditions)
- **Expected** (exact observable behaviour)
- **Result** (pass / fail + notes after running)
