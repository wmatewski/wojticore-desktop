# RPM release process

## Package and repository layout

Each packages/<name>/ directory has an independent spec and source. glass-desktop is a dependency-only meta package. Runtime modules and session files are split across glass-ui, glass-shell, glass-dock, glass-topbar, glass-launcher and glass-hyprland-config.

## Development and Stable

- Pushes to main publish Development after CI passes.
- A vX.Y.Z tag publishes Stable after CI passes.
- RPMs and repository metadata are signed with the same public key distributed to users.
- The publisher uploads RPMs and signed repomd.xml first, then writes the API latest.json pointer. Enable bucket object versioning so operators can restore a previous pointer and metadata generation.

GitHub Actions requires these repository variables/secrets:

| Name | Kind | Purpose |
|---|---|---|
| DOPPLER_DESKTOP_TOKEN | secret | Read-only token scoped to the RPM signing config |
| DOPPLER_CONFIG | variable | Doppler config, default prd |
| GCP_WIF_PROVIDER | variable | Workload Identity Federation provider resource name |
| GCP_PUBLISHER_SERVICE_ACCOUNT | variable | Dedicated service account used by RPM publication |
| GCS_BUCKET | variable | Public repository bucket |
| DEPLOY_FRONTEND | variable | Set to true after Cloudflare setup |
| CLOUDFLARE_ACCOUNT_ID | variable | Cloudflare account ID |
| CF_API_TOKEN | secret | Cloudflare token restricted to Workers script deployment |

The Doppler config must contain RPM_GPG_PRIVATE_KEY (ASCII armored key) and RPM_GPG_KEY_ID. Keep this signing key separate from the Cloud Build Doppler service token. Never print downloaded secret values or commit the key.

## Manual repository setup

1. Create a public GCS bucket and enable uniform bucket-level access and object versioning.
2. Upload the exported RPM public key to keys/RPM-GPG-KEY-wojticore.
3. Grant anonymous read access only for the public artifacts bucket. Do not grant public write access.
4. Create a Workload Identity Federation provider for GitHub Actions. Bind only this repository and the publication workflow to the dedicated publisher account.
5. Grant that account roles/storage.objectAdmin on the RPM bucket so it can create RPM objects and replace the changing repository metadata and latest manifest. It does not need project-wide Storage Admin.
6. Add the GitHub variables/secrets above, then run the RPM workflow manually against Development before creating a Stable tag. Protect v* tags with a repository ruleset so only release maintainers can publish Stable.

publish-rpms.sh duplicates the architecture-independent alpha packages into x86_64 and aarch64 repositories. If architecture-specific binaries are introduced, change the builder/publisher to select matching RPM architectures before publishing.
