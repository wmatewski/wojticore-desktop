#!/usr/bin/env bash
set -euo pipefail

out_dir="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/wojticore-desktop/rpm-signing}"
command -v gpg >/dev/null || { echo 'gpg is required (install gnupg2 on Fedora).' >&2; exit 1; }
[[ ! -e "$out_dir" ]] || { echo "Refusing to overwrite existing directory: $out_dir" >&2; exit 1; }
umask 077
mkdir -p "$out_dir/gnupg"
chmod 700 "$out_dir" "$out_dir/gnupg"
keyring="$out_dir/gnupg"
uid='Wojticore Desktop RPM Signing <rpm-signing@wojticore.invalid>'

gpg --homedir "$keyring" --batch --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" rsa4096 sign 2y
fingerprint="$(gpg --homedir "$keyring" --batch --with-colons --list-secret-keys "$uid" | awk -F: '$1 == "fpr" { print $10; exit }')"
key_id="$(gpg --homedir "$keyring" --batch --with-colons --list-secret-keys "$uid" | awk -F: '$1 == "sec" { print $5; exit }')"
[[ -n "$fingerprint" && -n "$key_id" ]] || { echo 'Could not read the generated GPG key identity.' >&2; exit 1; }

gpg --homedir "$keyring" --batch --armor --export-secret-keys "$fingerprint" > "$out_dir/private-key.asc"
gpg --homedir "$keyring" --batch --armor --export "$fingerprint" > "$out_dir/public-key.asc"
[[ -s "$out_dir/private-key.asc" && -s "$out_dir/public-key.asc" ]] || { echo 'GPG key export failed.' >&2; exit 1; }
printf '%s\n' "$key_id" > "$out_dir/key-id.txt"
chmod 600 "$out_dir/private-key.asc" "$out_dir/key-id.txt"
chmod 644 "$out_dir/public-key.asc"

printf 'Created signing key files in %s\n' "$out_dir"
printf 'Key ID: %s\n' "$key_id"
printf 'Set Doppler RPM_GPG_PRIVATE_KEY from private-key.asc and RPM_GPG_KEY_ID from key-id.txt.\n'
