# Release API

Base URL: https://api.desktop.wojticore.eu

## Health

GET /healthz returns 200 {"status":"ok"}. This reports process health and does not call GCS.

## Latest release

GET /v1/releases/latest?channel=stable&architecture=x86_64

Supported channels: stable and development. Supported architectures: x86_64 and aarch64. Defaults are stable and x86_64.

The API reads channels/<channel>/<architecture>/latest.json from RELEASES_BUCKET. It returns 404 when the object is absent, 502 when its document is invalid, and 503 if GCS cannot be reached.

## Update check

GET /v1/updates/check?current=0.1.0-alpha.1&channel=development&architecture=x86_64

Returns the latest manifest with a SemVer comparison:

    {
      "current": "0.1.0-alpha.1",
      "updateAvailable": true,
      "latest": {
        "version": "0.1.0-alpha.2",
        "channel": "development",
        "architecture": "x86_64",
        "publishedAt": "2026-11-13T12:00:00Z",
        "packages": [
          {
            "name": "glass-shell",
            "version": "0.1.0-alpha.2",
            "url": "https://storage.googleapis.com/wojticore-desktop-releases/repos/development/x86_64/glass-shell.rpm",
            "sha256": "<64 hexadecimal characters>"
          }
        ]
      }
    }

Manifest URLs must use HTTPS and package hashes must be SHA-256. An invalid current version returns 400.
