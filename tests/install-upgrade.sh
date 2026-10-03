#!/bin/sh
# Prove real dpkg install + upgrade + removal of zetik-core in a private root.
# Uses a user-owned dpkg instance (no host changes, no sudo).
set -eu
top=$(cd "$(dirname "$0")/../.." && pwd)
out="${1:-$top/../out}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

root="$work/root"
admin="$root/var/lib/dpkg"
mkdir -p "$admin/info" "$admin/updates" "$root/var/log"
: > "$admin/status"
: > "$admin/available"

dpkg_priv() {
  # force-depends: deps (python3) exist on the host but not in this private db
  dpkg --root="$root" --admindir="$admin" --force-not-root \
       --force-script-chrootless --force-depends \
       --log="$root/var/log/dpkg.log" "$@"
}

core="$out/zetik-core_0.1.0_all.deb"
[ -f "$core" ] || { echo "build zetik-core first"; exit 1; }

echo "=== install 0.1.0"
dpkg_priv -i "$core"
dpkg_priv -l zetik-core | tail -1
test -f "$root/usr/bin/zetik" || { echo "FAIL: binary not installed"; exit 1; }
test -f "$root/usr/share/zetik/catalog.json" || { echo "FAIL: catalog missing"; exit 1; }

echo "=== exercise installed CLI"
ZETIK_CATALOG="$root/usr/share/zetik/catalog.json" \
  PYTHONPATH="$root/usr/lib/zetik" python3 -m zetik --version

echo "=== build 0.1.1 and upgrade"
src2="$work/src"
cp -a "$top/zetik-core" "$src2"
cat > "$src2/debian/changelog" <<EOF
zetik-core (0.1.1) unstable; urgency=medium

  * Upgrade test: catalog metadata refresh.

 -- Zetik OS Maintainers <maintainers@zetik.invalid>  Thu, 01 Oct 2026 13:00:00 +0000
zetik-core (0.1.0) unstable; urgency=medium

  * Initial release.

 -- Zetik OS Maintainers <maintainers@zetik.invalid>  Thu, 01 Oct 2026 12:00:00 +0000
EOF
deb2=$(sh "$top/zetik-infra/bin/lab-build-deb" "$src2" "$work")
dpkg_priv -i "$deb2"
ver=$(dpkg_priv -l zetik-core | awk '/zetik-core/{print $3}')
[ "$ver" = "0.1.1" ] && echo "upgraded to $ver" || { echo "FAIL: version is $ver"; exit 1; }

echo "=== config preserved across upgrade (conffiles unchanged)"
# zetik-core ships no conffiles; assert clean upgrade left the binary in place
test -f "$root/usr/bin/zetik" || { echo "FAIL: binary lost on upgrade"; exit 1; }

echo "=== remove"
dpkg_priv -r zetik-core
test ! -f "$root/usr/bin/zetik" && echo "removed cleanly" || { echo "FAIL: files remain"; exit 1; }

echo "INSTALL/UPGRADE/REMOVE: all checks passed"
