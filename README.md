# TimeBuddy

AI-powered time zone converter for macOS. Type any time in natural language — Korean, English, Chinese — and get instant conversions across your configured time zones.

## Download

Website: https://pado-labs.github.io/TimeBuddy/

Download the latest release from [GitHub Releases](https://github.com/pado-labs/TimeBuddy/releases/latest).

- PKG installer: download the `.pkg` and double‑click to install (if Gatekeeper warns, right‑click → Open).
- ZIP: download, unzip, and drag `TimeBuddy.app` to Applications.

**Requirements:** macOS 14.0 (Sonoma) or later

## Project Structure

```
TimeBuddy/
├── apps/
│   ├── macos/      # macOS menu bar app (SwiftUI)
│   └── web/        # Landing page (Astro + Tailwind)
├── .github/
│   └── workflows/
│       ├── release.yml      # Build & release on tag push
│       └── deploy-web.yml   # Deploy website to GitHub Pages
```

## Development

### macOS App

```bash
cd apps/macos
xcodegen generate
open TimeBuddy.xcodeproj
```

### Website

```bash
cd apps/web
npm install
npm run dev
```

## Releasing

Push a version tag to trigger a GitHub Release with the built `.app` bundle:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This will:
1. Build the macOS app (Universal Binary: arm64 + x86_64)
2. Package it as a `.zip`
3. Create a GitHub Release with the download attached

## License

MIT
