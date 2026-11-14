#!/usr/bin/env bash
set -euo pipefail

: "${GCS_BUCKET:?Set GCS_BUCKET to the public RPM bucket}"
: "${RELEASE_VERSION:?Set RELEASE_VERSION to a semver release, for example 0.1.0-alpha.1}"
channel="${CHANNEL:-development}"
[[ "$channel" == stable || "$channel" == development ]] || { echo 'CHANNEL must be stable or development.' >&2; exit 2; }
command -v gsutil >/dev/null && command -v createrepo_c >/dev/null || { echo 'gsutil and createrepo_c are required.' >&2; exit 1; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rpm_dir="${RPM_OUTPUT_DIR:-$root/dist/rpms}"
[[ -n "$(find "$rpm_dir" -maxdepth 1 -name '*.rpm' -print -quit)" ]] || { echo "No RPMs found in $rpm_dir" >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
base_url="${PUBLIC_BASE_URL:-https://storage.googleapis.com/${GCS_BUCKET}}"

for arch in x86_64 aarch64; do
  repo="$work/repos/$channel/$arch"
  mkdir -p "$repo"
  cp "$rpm_dir"/*.rpm "$repo/"
  createrepo_c --update "$repo"
  if [[ -n "${RPM_SIGNING_KEY_ID:-}" ]]; then
    gpg --batch --yes --local-user "$RPM_SIGNING_KEY_ID" --armor --detach-sign "$repo/repodata/repomd.xml"
  else
    echo 'RPM_SIGNING_KEY_ID is required for signed repository metadata.' >&2
    exit 1
  fi
  gsutil -m rsync -r "$repo" "gs://${GCS_BUCKET}/repos/$channel/$arch/"
  python3 - "$rpm_dir" "$channel" "$arch" "$RELEASE_VERSION" "$base_url" "$work/latest-$channel-$arch.json" <<'PY'
import hashlib, json, pathlib, subprocess, sys, urllib.parse
rpm_dir, channel, arch, version, base_url, output = sys.argv[1:]
packages = []
for path in sorted(pathlib.Path(rpm_dir).glob('*.rpm')):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    name = subprocess.check_output(['rpm', '-qp', '--qf', '%{NAME}', str(path)], text=True)
    packages.append({
        'name': name,
        'version': version,
        'url': f"{base_url}/repos/{channel}/{arch}/{urllib.parse.quote(path.name)}",
        'sha256': digest,
    })
manifest = {
    'version': version,
    'channel': channel,
    'architecture': arch,
    'publishedAt': __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat(),
    'packages': packages,
}
pathlib.Path(output).write_text(json.dumps(manifest, indent=2) + '\n')
PY
done
cat > "$work/wojticore-desktop.repo" <<REPO
[wojticore-desktop-$channel]
name=Wojticore Desktop ($channel)
baseurl=$base_url/repos/$channel/\$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$base_url/keys/RPM-GPG-KEY-wojticore
metadata_expire=5m
REPO
gsutil cp "$work/wojticore-desktop.repo" "gs://$GCS_BUCKET/repos/$channel/wojticore-desktop.repo"
for arch in x86_64 aarch64; do
  gsutil cp "$work/latest-$channel-$arch.json" "gs://$GCS_BUCKET/channels/$channel/$arch/latest.json"
done
printf 'Published %s release %s to gs://%s\n' "$channel" "$RELEASE_VERSION" "$GCS_BUCKET"
