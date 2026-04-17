# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest (`main`) | Yes |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

If you discover a security issue in this plugin — such as a bypass of the security scanner,
a path traversal vulnerability in the sync logic, or a prompt injection vector that the scanner
fails to catch — please report it privately:

1. Use [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
   on this repo, or
2. Open a blank issue and ask a maintainer to convert it to a private advisory.

Include:
- A description of the vulnerability
- Steps to reproduce (e.g. a crafted remote `SKILL.md` that bypasses detection)
- Potential impact
- Suggested fix if you have one

You will receive an acknowledgment within 72 hours. If confirmed, a fix will be
prioritised and a patch released as soon as possible.

---

## Security Model

This plugin's built-in security scanner (documented in [`security.md`](../security.md)) runs
on every remote file before it is written to disk. It blocks:

- Prompt injection attempting to override Claude's behaviour
- Code execution via `eval`, `exec`, `subprocess`, etc.
- Credential harvesting (reading sensitive local files)
- Self-modification (overwriting the plugin's own instruction files)

This scanner is a best-effort defence, not a guarantee. Only add repos you trust.
