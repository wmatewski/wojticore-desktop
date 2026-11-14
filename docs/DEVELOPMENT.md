# Development

## Backend

    cd backend
    npm ci
    npm test
    npm run build
    RELEASES_BUCKET=wojticore-desktop-releases npm run dev

The API uses Google Application Default Credentials. For local GCS reads, install Google Cloud CLI and run gcloud auth application-default login with an identity that can read the release bucket. The API requires a populated channels/<channel>/<architecture>/latest.json object.

To test Doppler startup loading, create a read-only Doppler service token scoped to the wojticore-desktop / prd config and export DOPPLER_TOKEN, DOPPLER_PROJECT, and DOPPLER_CONFIG. Do not put a Google service account key in Doppler; Cloud Run ADC and local ADC are used for GCS.

## Frontend

    cd frontend
    npm ci
    npm run check
    npm run build
    npm run preview

Astro outputs static files to frontend/dist; Wrangler serves that folder as Worker static assets. The QML preview and wallpaper are visual-only website content. The real desktop shell uses the QML sources under packages/.

## RPM packages

On Fedora:

    sudo dnf install rpm-build rpm-sign createrepo_c
    ./scripts/build-rpms.sh

Output is written to dist/rpms. The build script scans each packages/*/*.spec, creates a source tarball and builds each package independently. To sign locally, import the RPM GPG key into your GPG keyring and set RPM_SIGNING_KEY_ID before running the build.

glass-session copies the shipped Lua config only when ~/.config/wojticore-glass/hyprland.lua is absent. If an older Glass config exists, it keeps a `.legacy-backup` copy and starts with the supported Lua defaults. It runs `start-hyprland` when available and does not source or rewrite the user's ordinary Hyprland config.

## Quickshell

Install the current Fedora Quickshell package, then test the shell with:

    quickshell -p packages/glass-shell/files/Shell.qml

For local component imports, add each packages/*/files QML directory to QML_IMPORT_PATH, or use the RPM build/install paths described in docs/RELEASING.md. The Meta+Space binding is registered through Hyprland global shortcuts; the dock uses the glass-launcher IPC target.
