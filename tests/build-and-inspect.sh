#!/bin/sh
# Build every component package and run checks that need no root.
set -eu
top=$(cd "$(dirname "$0")/../.." && pwd)
out="${1:-$top/../out}"
mkdir -p "$out"
rc=0

for comp in zetik-core zetik-artwork zetik-xfce zetik-bspwm zetik-boot zetik-login; do
  [ -f "$top/$comp/debian/control" ] || continue
  echo "=== $comp: unit tests"
  if [ -d "$top/$comp/tests" ] && ls "$top/$comp/tests"/test_*.py >/dev/null 2>&1; then
    (cd "$top/$comp" && python3 -m unittest discover -s tests 2>&1 | tail -3) || rc=1
  fi
  # Run any shell tests shipped with the component
  for st in "$top/$comp/tests"/test_*.sh; do
    [ -f "$st" ] || continue
    sh "$st" >/dev/null 2>&1 && echo "shell test ok: $(basename "$st")" || { echo "shell test FAIL: $st"; rc=1; }
  done
  # zetik-login ships a generated greeter background
  if [ "$comp" = "zetik-login" ]; then
    python3 "$top/zetik-login/bin/gen-background" >/dev/null || rc=1
  fi
  # zetik-artwork validates owner exports, then stages assets before packaging
  if [ "$comp" = "zetik-artwork" ]; then
    python3 "$top/zetik-artwork/bin/check-exports" || rc=1
    ZETIK_WALLPAPER_SCALE=0.25 sh "$top/zetik-artwork/bin/stage-assets" \
      "$top/zetik-artwork/staging" >/dev/null 2>&1 || rc=1
  fi
  echo "=== $comp: build"
  deb=$(sh "$top/zetik-infra/bin/lab-build-deb" "$top/$comp" "$out") || { rc=1; continue; }
  dpkg-deb --info "$deb" >/dev/null || rc=1
  echo "$(sha256sum "$deb")"
  x=$(mktemp -d)
  dpkg-deb -x "$deb" "$x"
  # Verify every shipped shell script parses
  for f in $(find "$x/usr/bin" "$x/usr/libexec" -type f 2>/dev/null); do
    if head -n1 "$f" | grep -q '^#!/bin/sh\|^#!/bin/bash'; then
      sh -n "$f" 2>/dev/null || bash -n "$f" || { echo "FAIL syntax: $f"; rc=1; }
    fi
  done
  rm -rf "$x"
done

echo "=== zetik-core: extracted CLI smoke test"
x=$(mktemp -d)
dpkg-deb -x "$out"/zetik-core_*_all.deb "$x"
export ZETIK_CATALOG="$x/usr/share/zetik/catalog.json" PYTHONPATH="$x/usr/lib/zetik"
python3 -m zetik --version || rc=1
python3 -m zetik catalog groups || rc=1
python3 -m zetik tools status | head -4
python3 -m zetik doctor && echo "doctor: clean" || echo "doctor: reported problems (exit $?)"
rm -rf "$x"
exit $rc
