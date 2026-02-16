# AGENTS Log

This document records every significant action performed by Oz (the agent) on this repository from 2026-02-16 onward.

- Policy: Each action that changes the repo will be committed with a clear message and include a co-author line.
- Non-file operations (auth, CI settings) will be logged here and committed.

## 2026-02-16
- [Init] Create AGENTS.md and enable action-by-action commits.

<!-- LOG: entries will be appended below this line -->
- [Auth] Switch GitHub CLI login to 'woohyeokk-choi' via web flow (HTTPS git protocol; scopes: repo, workflow).
- [Auth] Configure git credential helper via `gh auth setup-git` for HTTPS pushes.
- [Repo] Push 'main' branch to origin (pado-labs/TimeBuddy).
- [CI] Trigger GitHub Pages deploy workflow via push (deploy-web.yml).
