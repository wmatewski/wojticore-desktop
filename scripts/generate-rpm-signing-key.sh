#!/usr/bin/env bash
set -euo pipefail

out_dir="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/wojticore-desktop/rpm-signing}"
command -v gpg >/dev/null || { echo 'gpg is required (install gnupg2 on Fedora).' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'python3 is required to format the Doppler import payload.' >&2; exit 1; }
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

printf 'Created signing key files in %s\n' "$out_dir" >&2
printf 'The JSON on stdout contains the unencrypted private key; paste it only into Doppler Import Secrets > JSON.\n' >&2
python3 - "$out_dir" "$key_id" <<'PY'
import json, pathlib, sys
directory, key_id = pathlib.Path(sys.argv[1]), sys.argv[2]
print(json.dumps({
    'RPM_GPG_PRIVATE_KEY': (directory / 'private-key.asc').read_text(),
    'RPM_GPG_KEY_ID': key_id,
    'RELEASES_BUCKET': 'wojticore-desktop-releases-dev-952788006008',
}, indent=2))
PY
