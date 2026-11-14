# Google Cloud backend

This deployment targets project `wojticore-dev`, region `europe-west1`, and the `wojticore` Artifact Registry repository. Runtime and publisher identities are separate. Cloud Run accesses GCS through ADC using its attached service account; no Google service-account JSON key is used.

## Resources and identities

| Resource | Name | Access |
|---|---|---|
| Cloud Run service | `wojticore-desktop-backend` | Public read-only release API |
| Artifact Registry | `wojticore` (`europe-west1`) | Build identity: `roles/artifactregistry.writer`; Cloud Run pulls images |
| Release bucket | `wojticore-desktop-releases-dev-952788006008` | Public object reads; object versioning enabled |
| Runtime identity | `desktop-runtime@wojticore-dev.iam.gserviceaccount.com` | Bucket `roles/storage.objectViewer`; Secret Manager accessor on `DOPPLER_DESKTOP_TOKEN` |
| Build/deploy identity | `desktop-build@wojticore-dev.iam.gserviceaccount.com` | `roles/cloudbuild.builds.builder`, `roles/run.admin`, `roles/logging.logWriter`, `roles/serviceusage.serviceUsageConsumer`; Artifact Registry writer; service-account user on runtime identity |
| RPM publisher | `desktop-publisher@wojticore-dev.iam.gserviceaccount.com` | Bucket `roles/storage.objectAdmin`; GitHub Workload Identity Federation only |

Cloud Build uses Cloud Logging only. Its GitHub 2nd-generation host connection must be installed and linked to `wmatewski/wojticore-desktop` in `europe-west1`. The trigger is `wojticore-desktop-backend-main`, matches `main`, and includes only `backend/**` and `cloudbuild/**`; frontend and RPM-only changes do not deploy the API.

## Cloud Build GitHub connection

Cloud Build requires a one-time GitHub App authorization and installation. Start the connection from a signed-in Google Cloud CLI:

```sh
gcloud builds connections create github wojticore-github \
  --project=wojticore-dev --region=europe-west1
```

Open the authorization URL printed by the CLI, authorize the Cloud Build GitHub App, and install it for `wmatewski/wojticore-desktop`. This grants the app repository access; review its requested access before approving. After installation, verify `installationState: COMPLETE`, then link the repository:

```sh
gcloud builds repositories create wojticore-desktop \
  --remote-uri=https://github.com/wmatewski/wojticore-desktop.git \
  --connection=wojticore-github --region=europe-west1 \
  --project=wojticore-dev
```

The deploy trigger uses `cloudbuild/production.yaml`, and its included file filter is `backend/**,cloudbuild/**`. The config builds the backend container, pushes the commit-SHA image to Artifact Registry, deploys Cloud Run with the runtime identity, and verifies `/healthz`.

## Doppler secrets

`DOPPLER_DESKTOP_TOKEN` is already in Secret Manager and is referenced by Cloud Run at startup. Runtime access is scoped to that secret. Store the same read-only token in the GitHub Actions `prd` environment as `DOPPLER_DESKTOP_TOKEN` for RPM signing workflows.

The Doppler project/config used by the publishing workflows must contain:

| Secret | Purpose |
|---|---|
| `RELEASES_BUCKET` | Public release bucket name; the backend allowlists this value only |
| `RPM_GPG_PRIVATE_KEY` | ASCII-armored private key used to sign RPM packages and repository metadata |
| `RPM_GPG_KEY_ID` | GPG key ID matching the signing key |

Do not put a Google Cloud JSON key in Doppler. The current API reads only public release manifests from GCS and does not require another application secret. Keep the service token read-only and scoped to the config containing the signing material; use a separate restricted runtime token/config if the API later needs private Doppler values.

## GitHub Actions variables and environment

The protected `prd` environment must provide these variables to its publishing jobs:

| Variable | Value |
|---|---|
| `GCP_WIF_PROVIDER` | `projects/952788006008/locations/global/workloadIdentityPools/github-actions/providers/github` |
| `GCP_PUBLISHER_SERVICE_ACCOUNT` | `desktop-publisher@wojticore-dev.iam.gserviceaccount.com` |
| `GCS_BUCKET` | `wojticore-desktop-releases-dev-952788006008` |
| `DEPLOY_FRONTEND` | Set to `true` only after Cloudflare credentials and the Worker are configured |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID, if frontend deployment is enabled |

`CF_API_TOKEN` is optional until Cloudflare frontend deployment is enabled; scope it to deploy the `wojticore-desktop` Worker only. The WIF provider accepts this repository's `main` branch and `v*` tags. Stable tag workflows validate semantic `vX.Y.Z` tags and require the tagged commit to be an ancestor of `main`.

## Verification and recovery

- Cloud Build publishes a source-commit SHA image and deploys only after backend or Cloud Build config changes.
- Confirm Cloud Run uses the runtime identity, bucket name, and `DOPPLER_DESKTOP_TOKEN` secret reference.
- Confirm anonymous users can download release objects but cannot upload.
- Bucket versioning allows restoring older DNF metadata and `channels/<channel>/<architecture>/latest.json` generations.
- Cloud Run `/healthz` does not require GCS; release endpoints return `503` if GCS is unavailable.
