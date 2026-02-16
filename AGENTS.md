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
- [Release] Create and push tag v1.0.0 to trigger release workflow.
- [Pages] Enable GitHub Pages with build_type=workflow and HTTPS enforced.
- [Pages] Manually dispatched Deploy Website workflow on main.
- [Web] Remove features row (emoji bullets) and redesign demo to match app UI (toolbar + rows + copy icons).
- [Web] Update hero input text to "next Tue 2–3pm in London" and add optional screenshot hook (`public/demo.png`).
- [Icons] Add script to generate minimalist clock app icon and update AppIcon.appiconset with filenames.
- [Web] Add demo screenshot at `apps/web/public/demo.png` and auto-hide mock on load.
- [CI] Deploy Website workflow triggered via push (web public asset).
- [App] Add "Launch at login" setting (writes LaunchAgent in ~/Library/LaunchAgents) and toggle in Settings.
- [Web] Footer: append pado-labs icon (public/pado-icon.svg).
- [Run] Local build (Debug) and launch via xcodebuild/open for verification.
- [Release] Update workflow to also package `.pkg` installer (pkgbuild) and upload alongside zip.
- [Docs] README: add website URL and install notes (PKG/ZIP).
- [Docs] README: add Gatekeeper workaround (System Settings → Privacy & Security → Open Anyway).
