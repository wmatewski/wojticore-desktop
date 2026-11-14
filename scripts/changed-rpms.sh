#!/usr/bin/env bash
set -euo pipefail

base="${1:?usage: changed-rpms.sh BASE HEAD}"
head="${2:?usage: changed-rpms.sh BASE HEAD}"
packages=(glass-desktop glass-dock glass-hyprland-config glass-launcher glass-shell glass-topbar glass-ui)
declare -A selected=()

if [[ "$base" == ALL ]]; then
  for package in "${packages[@]}"; do selected["$package"]=1; done
else
  while IFS= read -r path; do
    if [[ "$path" == scripts/build-rpms.sh || "$path" == scripts/changed-rpms.sh ]]; then
      for package in "${packages[@]}"; do selected["$package"]=1; done
    elif [[ "$path" =~ ^packages/([^/]+)/ ]]; then
      package="${BASH_REMATCH[1]}"
      [[ " ${packages[*]} " == *" $package "* ]] && selected["$package"]=1
    fi
  done < <(git diff --name-only "$base..$head")

  changed=1
  while (( changed )); do
    changed=0
    for dependency in "${!selected[@]}"; do
      case "$dependency" in
        glass-ui) dependents=(glass-dock glass-topbar glass-launcher glass-shell) ;;
        glass-dock|glass-topbar|glass-launcher) dependents=(glass-shell) ;;
        glass-shell) dependents=(glass-hyprland-config) ;;
        *) dependents=() ;;
      esac
      for dependent in "${dependents[@]}"; do
        if [[ -z "${selected[$dependent]:-}" ]]; then selected["$dependent"]=1; changed=1; fi
      done
    done
  done
fi

result=""
for package in "${packages[@]}"; do
  if [[ -n "${selected[$package]:-}" ]]; then result="${result:+$result,}$package"; fi
done
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then printf 'packages=%s\n' "$result" >> "$GITHUB_OUTPUT"; else printf '%s\n' "$result"; fi
