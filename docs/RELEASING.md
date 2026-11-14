# RPM releases and CI

## Workflows

- `Main CI` runs on pull requests and pushes to `main`. It checks backend, frontend and RPMs only when their files changed. The `Main CI / gate` check is required for merging.
- Changes under `backend/**` or `cloudbuild/**` also start the Cloud Build trigger and deploy the backend after the main push.
- RPM changes build only the changed package and the transitive RPM consumers whose exact dependency versions must match. A change to `glass-ui` rebuilds its consumers; a `glass-hyprland-config`-only change builds that package alone.
- Pushes to `main` publish selected RPMs to Development. Tags `vX.Y.Z` publish selected RPMs to Stable; the tag must point to a commit on `main`.
- Frontend pushes deploy only when the `DEPLOY_FRONTEND` environment variable is `true`.

The publisher downloads the existing channel repository before regenerating its DNF metadata, so publishing one module retains previously published packages. RPMs and repository metadata are signed before the channel manifest is updated.

## Doppler configuration

The Doppler project/config used by publishing must contain:

| Name | Kind | Purpose |
|---|---|---|
| `RELEASES_BUCKET` | configuration | Public release bucket name, selectively loaded by the backend |
| `RPM_GPG_PRIVATE_KEY` | secret | ASCII-armored private key used for RPM and metadata signatures |
| `RPM_GPG_KEY_ID` | secret | GPG key ID matching the private key |

The `prd` GitHub Actions environment contains `DOPPLER_DESKTOP_TOKEN`, a read-only Doppler service token. Do not store Google Cloud account JSON in Doppler. GitHub uses Workload Identity Federation for GCP and Cloud Run uses its attached service account for ADC.

RPM publication remains disabled while `PUBLISH_RPMS=false`. After adding both `RPM_GPG_PRIVATE_KEY` and `RPM_GPG_KEY_ID` to the Doppler `prd` config and verifying the public signing key is published with the repository, set the `prd` environment variable `PUBLISH_RPMS=true` to enable Development and Stable publication.

## GitHub configuration

The `prd` environment provides `GCP_WIF_PROVIDER`, `GCP_PUBLISHER_SERVICE_ACCOUNT`, `GCS_BUCKET`, `DOPPLER_DESKTOP_TOKEN`, and optional Cloudflare deployment values. See [Google Cloud backend](GOOGLE_CLOUD.md) for their names and scopes.

The RPM publisher identity is restricted to the release bucket and this repository's GitHub OIDC identity. Its bucket role is `roles/storage.objectAdmin` because it replaces signed DNF metadata and channel manifests. Runtime and build service identities are separate; see the Google Cloud guide for each role.
