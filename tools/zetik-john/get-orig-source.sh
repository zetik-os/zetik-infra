#!/bin/sh
# Fetch a pinned John the Ripper jumbo source into an orig tarball.
# Pin a tag or commit so builds are reproducible. Run before dpkg-buildpackage.
set -eu
ver="${1:-1.9.0+jumbo1}"
ref="${2:-1.9.0-Jumbo-1}"
work=$(mktemp -d)
git clone --depth 1 --branch "$ref" https://github.com/openwall/john "$work/john"
rm -rf "$work/john/.git"
tar -C "$work" -caf "zetik-john_${ver}.orig.tar.gz" john
rm -rf "$work"
echo "wrote zetik-john_${ver}.orig.tar.gz"
