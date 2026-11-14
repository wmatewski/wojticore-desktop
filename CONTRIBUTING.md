# Contributing

1. Open an issue for larger changes and keep changes scoped to one package or service.
2. Run backend tests and builds, frontend build, and RPM validation for affected packages.
3. Do not commit secrets, generated RPMs, Doppler tokens, service account keys or user configuration.
4. Keep each `packages/*` directory independently buildable and versioned.
5. Alpha releases use Development first; Stable publication requires a reviewed release tag.

See [development](docs/DEVELOPMENT.md) and [release process](docs/RELEASING.md).
