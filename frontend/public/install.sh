#!/usr/bin/env bash
set -euo pipefail

channel="${CHANNEL:-stable}"
releases_bucket=wojticore-desktop-releases-dev-952788006008
if [[ -v RELEASES_BUCKET ]]; then releases_bucket="$RELEASES_BUCKET"; fi
[[ "$releases_bucket" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]] || { echo "Invalid GCS bucket name: $releases_bucket" >&2; exit 2; }
case "$channel" in stable|development) ;; *) echo 'CHANNEL must be stable or development.' >&2; exit 2 ;; esac
[[ "$(id -u)" -eq 0 ]] || { echo 'Run with sudo or as root.' >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo 'Cannot identify this Linux distribution.' >&2; exit 1; }
. /etc/os-release
[[ "${ID:-}" == fedora ]] || { echo 'Glass Desktop currently supports Fedora only.' >&2; exit 1; }
command -v dnf >/dev/null || { echo 'dnf is required.' >&2; exit 1; }

repo_file="/etc/yum.repos.d/wojticore-desktop-${channel}.repo"
expected="$(cat <<REPO
[wojticore-desktop-${channel}]
name=Wojticore Desktop (${channel})
baseurl=https://storage.googleapis.com/$releases_bucket/repos/${channel}/\$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://storage.googleapis.com/$releases_bucket/keys/RPM-GPG-KEY-wojticore
metadata_expire=5m
REPO
)"
if [[ -e "$repo_file" ]]; then
  if [[ "$(cat "$repo_file")" != "$expected" ]]; then
    echo "An existing repository file differs: $repo_file" >&2
    read -r -p 'Replace it? [y/N] ' answer
    [[ "$answer" == [yY] ]] || { echo 'Installation cancelled; existing file was preserved.'; exit 1; }
  else
    echo 'Wojticore repository is already configured.'
  fi
fi
if [[ ! -e "$repo_file" ]] || [[ "$(cat "$repo_file")" != "$expected" ]]; then
  install -d -m 755 /etc/yum.repos.d
  temp_file="$(mktemp /etc/yum.repos.d/.wojticore-XXXXXX)"
  chmod 644 "$temp_file"
  printf '%s\n' "$expected" > "$temp_file"
  mv -f "$temp_file" "$repo_file"
fi

dnf --refresh --disablerepo='wojticore-desktop-*' --enablerepo="wojticore-desktop-${channel}" install -y glass-desktop
printf '\nGlass Desktop has been installed. Select “Glass Desktop” from your login screen.\n'
printf 'Existing desktop sessions and user configuration were left in place.\n'
