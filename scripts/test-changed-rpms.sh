#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -C "$work" init -q
git -C "$work" -c user.name=Test -c user.email=test@example.invalid commit --allow-empty -qm base
base="$(git -C "$work" rev-parse HEAD)"

assert_selection() {
  local path="$1" expected="$2"
  mkdir -p "$work/$(dirname "$path")"
  : > "$work/$path"
  git -C "$work" add "$path"
  git -C "$work" -c user.name=Test -c user.email=test@example.invalid commit -qm change
  local head actual
  head="$(git -C "$work" rev-parse HEAD)"
  actual="$(cd "$work" && env -u GITHUB_OUTPUT "$root/scripts/changed-rpms.sh" "$base" "$head")"
  [[ "$actual" == "$expected" ]] || { printf 'Expected %s, got %s for %s\n' "$expected" "$actual" "$path" >&2; exit 1; }
  base="$head"
}

assert_selection packages/glass-topbar/files/Topbar.qml glass-hyprland-config,glass-shell,glass-topbar
assert_selection packages/glass-ui/files/Theme.qml glass-dock,glass-hyprland-config,glass-launcher,glass-shell,glass-topbar,glass-ui
assert_selection packages/glass-hyprland-config/files/default-hyprland.conf glass-hyprland-config
assert_selection scripts/build-rpms.sh glass-desktop,glass-dock,glass-hyprland-config,glass-launcher,glass-shell,glass-topbar,glass-ui
printf 'Changed RPM selection tests passed.\n'
