#!/usr/bin/env bash
# bump.sh <version> <amd64.deb> <arm64.deb>: the PKGBUILD beside it for that release, and its .SRCINFO (makepkg's).
set -euo pipefail
version=$1 x64=$2 arm=$3
cd "$(dirname "$0")"
sum() { sha256sum "$1" | cut -d' ' -f1; }
sed -i -e "s/^pkgver=.*/pkgver=$version/" -e "s/^pkgrel=.*/pkgrel=1/" \
  -e "s/^sha256sums_x86_64=.*/sha256sums_x86_64=('$(sum "$x64")')/" -e "s/^sha256sums_aarch64=.*/sha256sums_aarch64=('$(sum "$arm")')/" PKGBUILD
makepkg --printsrcinfo > .SRCINFO
