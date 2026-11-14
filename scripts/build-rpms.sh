#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
command -v rpmbuild >/dev/null || { echo 'rpmbuild is required (install rpm-build).' >&2; exit 1; }
out="$root/dist/rpms"
if printenv RPM_OUTPUT_DIR >/dev/null 2>&1; then out="$RPM_OUTPUT_DIR"; fi
selected_packages="${RPM_PACKAGES:-}"
rpm_semver=0.1.0-alpha.1
if printenv RPM_VERSION >/dev/null 2>&1; then rpm_semver="$RPM_VERSION"; fi
[[ "$rpm_semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][A-Za-z0-9.-]+)?$ ]] || { echo 'RPM_VERSION must be a valid release version such as 0.1.0-alpha.1.' >&2; exit 2; }
rpm_version="$(printf '%s' "$rpm_semver" | sed 's/-/~/')"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"

declare -A selected=()
if [[ -n "$selected_packages" ]]; then
  IFS=',' read -r -a requested <<< "$selected_packages"
  for package in "${requested[@]}"; do
    [[ "$package" =~ ^glass-[a-z0-9-]+$ && -f "$root/packages/$package/$package.spec" ]] || { echo "Unknown RPM package: $package" >&2; exit 2; }
    selected["$package"]=1
  done
fi

while IFS= read -r spec; do
  package_dir="$(dirname "$spec")"
  package="$(basename "$package_dir")"
  if [[ -n "$selected_packages" && -z "${selected[$package]:-}" ]]; then continue; fi
  pkg_work="$work/$package"
  mkdir -p "$pkg_work/SOURCES" "$pkg_work/BUILD" "$pkg_work/RPMS" "$pkg_work/SPECS" "$pkg_work/SRPMS"
  build_spec="$pkg_work/SPECS/$package.spec"
  sed "s/^Version:.*/Version:        $rpm_version/" "$spec" > "$build_spec"
  if [[ "$package" != glass-desktop ]]; then
    source_dir="$pkg_work/src/$package-$rpm_version"
    mkdir -p "$source_dir"
    cp -a "$package_dir/files" "$source_dir/"
    tar -czf "$pkg_work/SOURCES/$package-$rpm_version.tar.gz" -C "$pkg_work/src" "$package-$rpm_version"
  fi
  rpmbuild -ba --define "_topdir $pkg_work" "$build_spec"
  find "$pkg_work/RPMS" -type f -name '*.rpm' -exec cp -f {} "$out/" \;
done < <(find "$root/packages" -mindepth 2 -maxdepth 2 -name '*.spec' -type f | sort)

if printenv RPM_SIGNING_KEY_ID >/dev/null 2>&1; then
  command -v rpmsign >/dev/null || { echo 'rpmsign is required to sign packages.' >&2; exit 1; }
  shopt -s nullglob
  for rpm in "$out"/*.rpm; do rpmsign --addsign --define "_gpg_name $RPM_SIGNING_KEY_ID" "$rpm"; done
fi
printf 'Built RPMs version %s in %s\n' "$rpm_semver" "$out"
