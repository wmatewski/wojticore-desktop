#!/usr/bin/env bash
set -euo pipefail
: "${RPM_SIGNING_KEY_ID:?Set RPM_SIGNING_KEY_ID after importing the private key}"
shopt -s nullglob
rpms=("${RPM_OUTPUT_DIR:-dist/rpms}"/*.rpm)
((${#rpms[@]})) || { echo 'No RPMs to sign.' >&2; exit 1; }
for rpm in "${rpms[@]}"; do rpmsign --addsign --define "_gpg_name ${RPM_SIGNING_KEY_ID}" "$rpm"; done
