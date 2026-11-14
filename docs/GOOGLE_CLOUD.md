# Manual Google Cloud setup

This repository intentionally does not create or update Google Cloud resources. Run these steps manually after reviewing the project and current policies. Examples use project wojticore-desktop and region europe-west1; use the existing Cloud Build 2nd gen connection region if it differs. Set PROJECT_ID=wojticore-desktop and REGION=europe-west1 in your shell before using the commands.

## 1. Check the existing project and connection first

    gcloud config set project wojticore-desktop
    gcloud projects describe wojticore-desktop
    gcloud builds connections list --region=europe-west1
    gcloud builds repositories list --region=europe-west1
    gcloud run services list --region=europe-west1
    gcloud artifacts repositories list --location=europe-west1
    gcloud storage buckets list
    gcloud secrets list

The initial workspace inspection found the project active, but Cloud Build and Secret Manager APIs were disabled and the current user lacked Secret Manager access. Recheck before enabling APIs or creating resources. Do not create another GitHub connection if the existing connection can be reused. If the repo is not attached to it, attach it using that connection only:

    gcloud builds repositories create wojticore-desktop \
      --remote-uri=https://github.com/wmatewski/wojticore-desktop.git \
      --connection=EXISTING_CONNECTION \
      --region=EXISTING_CONNECTION_REGION

## 2. Enable APIs and prepare resources

An administrator with serviceusage.services.enable should enable only the APIs used by this deployment:

    gcloud services enable \
      run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com \
      storage.googleapis.com secretmanager.googleapis.com iam.googleapis.com iamcredentials.googleapis.com \
      --project=wojticore-desktop

Create the Artifact Registry repository only if it is absent:

    gcloud artifacts repositories create desktop \
      --repository-format=docker --location=europe-west1 \
      --project=wojticore-desktop

Create the release bucket only after checking that its globally unique name is available:

    gcloud storage buckets create gs://wojticore-desktop-releases \
      --project=wojticore-desktop --location=europe-west1 \
      --uniform-bucket-level-access
    gcloud storage buckets update gs://wojticore-desktop-releases --versioning

The bucket contains public RPMs and DNF metadata. Grant allUsers roles/storage.objectViewer on this bucket only after validating that every object placed there is intended for public download. Never grant public write access. Upload only the exported public RPM signing key under keys/RPM-GPG-KEY-wojticore. Keep private keys in Doppler.

## 3. Create service accounts and apply least-privilege IAM

Create separate accounts if equivalent existing accounts are not already available:

    gcloud iam service-accounts create desktop-runtime --project=wojticore-desktop
    gcloud iam service-accounts create cloud-build-desktop --project=wojticore-desktop
    gcloud iam service-accounts create desktop-rpm-publisher --project=wojticore-desktop

Runtime account — attach this identity to Cloud Run. It uses ADC, not a service account key:

    gcloud storage buckets add-iam-policy-binding gs://wojticore-desktop-releases \
      --member=serviceAccount:desktop-runtime@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/storage.objectViewer

If Doppler startup secret loading is enabled, grant runtime access on the single token secret only:

    gcloud secrets add-iam-policy-binding DOPPLER_DESKTOP_TOKEN \
      --project=wojticore-desktop \
      --member=serviceAccount:desktop-runtime@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/secretmanager.secretAccessor

Cloud Build account — it builds/pushes the API image, deploys Cloud Run and writes logs:

    gcloud projects add-iam-policy-binding wojticore-desktop \
      --member=serviceAccount:cloud-build-desktop@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/cloudbuild.builds.builder
    gcloud projects add-iam-policy-binding wojticore-desktop \
      --member=serviceAccount:cloud-build-desktop@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/run.admin
    gcloud projects add-iam-policy-binding wojticore-desktop \
      --member=serviceAccount:cloud-build-desktop@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/logging.logWriter
    gcloud artifacts repositories add-iam-policy-binding desktop \
      --location=europe-west1 --project=wojticore-desktop \
      --member=serviceAccount:cloud-build-desktop@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/artifactregistry.writer
    gcloud iam service-accounts add-iam-policy-binding \
      desktop-runtime@wojticore-desktop.iam.gserviceaccount.com \
      --project=wojticore-desktop \
      --member=serviceAccount:cloud-build-desktop@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/iam.serviceAccountUser

Do not grant Cloud Build write access to the RPM bucket; GitHub publication uses a separate identity. The Cloud Run runtime account, rather than the deployer, reads the Doppler token secret.

RPM publisher — bind GitHub Actions through Workload Identity Federation; do not create a service account key. Grant the publisher bucket-scoped roles/storage.objectAdmin because the pipeline replaces DNF metadata and the latest manifest as well as creating RPM objects:

    gcloud storage buckets add-iam-policy-binding gs://wojticore-desktop-releases \
      --member=serviceAccount:desktop-rpm-publisher@wojticore-desktop.iam.gserviceaccount.com \
      --role=roles/storage.objectAdmin

Configure a Workload Identity Federation pool/provider for GitHub and bind only this repository's main branch and v* release tags:

    gcloud iam workload-identity-pools create github-actions \
      --location=global --project=$PROJECT_ID
    gcloud iam workload-identity-pools providers create-oidc github \
      --location=global --workload-identity-pool=github-actions \
      --issuer-uri=https://token.actions.githubusercontent.com \
      --attribute-mapping=google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref \
      --attribute-condition="assertion.repository == 'wmatewski/wojticore-desktop' && (assertion.ref == 'refs/heads/main' || assertion.ref.startsWith('refs/tags/v'))" \
      --project=$PROJECT_ID
    PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
    gcloud iam service-accounts add-iam-policy-binding \
      desktop-rpm-publisher@$PROJECT_ID.iam.gserviceaccount.com \
      --project=$PROJECT_ID \
      --role=roles/iam.workloadIdentityUser \
      --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/attribute.repository/wmatewski/wojticore-desktop"

Set GitHub Actions variable GCP_WIF_PROVIDER to projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/providers/github and GCP_PUBLISHER_SERVICE_ACCOUNT to desktop-rpm-publisher@wojticore-desktop.iam.gserviceaccount.com. The publisher needs no project-wide Editor or Storage Admin role.

## 4. Add the Doppler token secret

Create a Doppler service token scoped to project wojticore-desktop and config prd. It should be read-only and restricted to the runtime config. Store it as the only application secret in Secret Manager:

    read -rsp 'Doppler service token: ' DOPPLER_TOKEN
    printf '\n'
    printf '%s' "$DOPPLER_TOKEN" | gcloud secrets create DOPPLER_DESKTOP_TOKEN \
      --project=wojticore-desktop --data-file=-
    unset DOPPLER_TOKEN

If the secret already exists, add a new version instead of creating a duplicate:

    read -rsp 'Doppler service token: ' DOPPLER_TOKEN
    printf '\n'
    printf '%s' "$DOPPLER_TOKEN" | gcloud secrets versions add DOPPLER_DESKTOP_TOKEN \
      --project=wojticore-desktop --data-file=-
    unset DOPPLER_TOKEN

Do not put a Google service account JSON key in Doppler. Cloud Run ADC supplies GCS credentials; for local development, use gcloud auth application-default login. Doppler is only for application secrets and RPM signing material.

## 5. Create the Cloud Build trigger

Use the connection region discovered above and the linked second-generation repository resource name. Create the trigger with the dedicated build account:

    gcloud builds triggers create github \
      --name=wojticore-desktop-backend-main \
      --repository=projects/wojticore-desktop/locations/EXISTING_CONNECTION_REGION/connections/EXISTING_CONNECTION/repositories/wojticore-desktop \
      --branch-pattern='^main$' \
      --build-config=cloudbuild/production.yaml \
      --region=EXISTING_CONNECTION_REGION \
      --service-account=projects/wojticore-desktop/serviceAccounts/cloud-build-desktop@wojticore-desktop.iam.gserviceaccount.com

The build config defaults to europe-west1, repository desktop, service wojticore-desktop-backend, bucket wojticore-desktop-releases and Doppler config prd. If your checked resources differ, set the corresponding substitutions on the trigger. Cloud Build publishes image tags containing the source commit SHA, not only latest.

## 6. Cloud Run service and API domain

The trigger deploys an unauthenticated, read-only release API with one CPU, 512 MiB, scale-to-zero and at most five instances. The runtime service account reads the bucket using ADC. Cloud Run injects DOPPLER_TOKEN from Secret Manager; the token is never copied into the image. Grant the Cloud Run service identity secretAccessor on that secret before first deployment.

After a successful deployment, map api.desktop.wojticore.eu to the Cloud Run service using Cloud Run domain mapping or the existing approved HTTPS load balancer. Follow the exact DNS records shown by Google Cloud; do not replace unrelated records. Verify HTTPS and GET /healthz.

## 7. Verify and recover

- Confirm the Cloud Build trigger uses the second-generation GitHub repository and the dedicated build service account.
- Confirm Cloud Run has the intended runtime service account, public invocation for read-only endpoints, secret reference and bucket name.
- Confirm anonymous users can download public RPM objects but cannot upload.
- Check Cloud Logging for health and startup failures; the application deliberately does not log Doppler secret values.
- Enable bucket object versioning before publishing. To roll back, restore the previous generations of repomd.xml, its signature and the affected latest.json object, then verify DNF metadata and the API response.
