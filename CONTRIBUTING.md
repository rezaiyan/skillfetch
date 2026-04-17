# Contributing to skillfetch

Thank you for considering a contribution. This project is a Claude Code plugin — its primary
source of truth is a set of Markdown instruction files consumed directly by Claude, not compiled
code. Keep that in mind when proposing changes.

---

## Ways to Contribute

- **Bug reports** — something behaves differently from what the docs say
- **New eval scenarios** — test cases that expose gaps in the current behaviour spec
- **Security rule improvements** — tighter patterns, fewer false positives
- **Documentation fixes** — typos, unclear phrasing, outdated examples
- **Feature proposals** — open an issue before writing code; discuss the design first

---

## Bug Reports

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

Include:
- The exact command you ran (e.g. `/skillfetch sync my-repo my-skill`)
- What Claude Code version you are using (`claude --version`)
- What happened vs. what you expected
- A minimal reproduction: which repo URL, which skill path, what the remote file looks like

---

## Pull Requests

1. **Open an issue first** for anything beyond a typo fix. Agree on the approach before investing time.
2. **One concern per PR.** Do not bundle unrelated changes.
3. **Update evals** if you change a command workflow — add or update a scenario in `evals/`.
4. **Do not add new external dependencies.** This plugin is intentionally dependency-free (pure shell + Markdown).
5. **Keep instruction files precise.** Claude executes these files literally. Vague wording causes
   real behavioural drift. Every sentence should describe an observable, verifiable action.

### PR checklist

- [ ] Issue linked
- [ ] Relevant `evals/` scenario added or updated
- [ ] No hardcoded project-type assumptions added (Android, Python, etc.)
- [ ] `security.md` updated if new fetch or write behaviour introduced

---

## Adding Eval Scenarios

Drop a file named `scenario-NN-short-description.md` in `evals/`. Follow the format in
`evals/README.md`: Input → Expected → Result (fill in after running).

Run evals manually in a **fresh Claude Code session** with no prior context of this skill loaded.

---

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be respectful.

---

## License

By contributing you agree your changes will be licensed under the [MIT License](LICENSE).