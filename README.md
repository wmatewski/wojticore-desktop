# Wojticore Desktop — Glass Desktop

Liquid Glass inspired Linux desktop environment built around Hyprland, Quickshell and Qt 6/QML. The 0.1.0 Alpha repository contains a minimal session, independent RPM packages, a release API and a static project website.

## Repository map

- `packages/` — independent RPM packages for the shell, panels, launcher, UI and session.
- `backend/` — stateless Node.js API for health, release and update queries.
- `frontend/` — Astro site deployed as Cloudflare Worker static assets.
- `installer/install.sh` — repeatable Fedora installer.
- `cloudbuild/` and `.github/workflows/` — build and publish pipelines.
- `docs/` — local development, release and manual infrastructure setup.

## Quick start

```sh
cd backend && npm ci && npm test && npm run build
cd ../frontend && npm ci && npm run build
```

Build RPM packages on Fedora with `rpm-build` and `createrepo_c` installed:

```sh
./scripts/build-rpms.sh
```

For a local API using Application Default Credentials, set `RELEASES_BUCKET` and authenticate with `gcloud auth application-default login`. See [development](docs/DEVELOPMENT.md) and [Google Cloud setup](docs/GOOGLE_CLOUD.md).

## Install

```sh
curl -fsSL https://desktop.wojticore.eu/install.sh | sudo bash
```

Review the script before running it. The script only supports Fedora and does not replace existing Hyprland, KDE or GNOME session configuration.

## Status

Alpha. The release API, website and packaging sources are implemented, but no Google Cloud, Cloudflare, DNS, GitHub repository settings or production release were created by this change.
