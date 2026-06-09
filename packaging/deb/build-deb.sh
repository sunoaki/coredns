#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
PACKAGE=${PACKAGE:-coredns}
MAINTAINER=${MAINTAINER:-Sunoaki Network LLC}
DESCRIPTION=${DESCRIPTION:-CoreDNS with nat64ptr plugin}
OUT_DIR=${OUT_DIR:-"$ROOT/dist"}
BUILD_ROOT=${BUILD_ROOT:-"$ROOT/build/deb"}
CORE_VERSION=$(awk -F '"' '/CoreVersion/ { print $2; exit }' "$ROOT/coremain/version.go")
VERSION=${VERSION:-"$CORE_VERSION-sunoaki"}

if command -v dpkg >/dev/null; then
    ARCH=${ARCH:-$(dpkg --print-architecture)}
else
    MACHINE=$(uname -m)
    case "$MACHINE" in
        x86_64) ARCH=amd64 ;;
        aarch64) ARCH=arm64 ;;
        armv7l) ARCH=armhf ;;
        *) ARCH=$MACHINE ;;
    esac
fi

if ! command -v dpkg-deb >/dev/null; then
    echo "dpkg-deb is required" >&2
    exit 1
fi

if ! grep -q '^nat64ptr:github.com/sunoaki/coredns-nat64ptr-plugin$' "$ROOT/plugin.cfg"; then
    echo "plugin.cfg must contain nat64ptr:github.com/sunoaki/coredns-nat64ptr-plugin" >&2
    exit 1
fi

(cd "$ROOT" && make coredns)

rm -rf "$BUILD_ROOT"
install -d "$BUILD_ROOT/DEBIAN"
install -d "$BUILD_ROOT/usr/bin"
install -d "$BUILD_ROOT/etc/coredns"
install -d "$BUILD_ROOT/lib/systemd/system"
install -d "$BUILD_ROOT/var/lib/coredns"

install -m 0755 "$ROOT/coredns" "$BUILD_ROOT/usr/bin/coredns"
install -m 0644 "$ROOT/packaging/deb/Corefile" "$BUILD_ROOT/etc/coredns/Corefile"
install -m 0644 "$ROOT/packaging/deb/coredns.service" "$BUILD_ROOT/lib/systemd/system/coredns.service"
install -m 0755 "$ROOT/packaging/deb/postinst" "$BUILD_ROOT/DEBIAN/postinst"
install -m 0755 "$ROOT/packaging/deb/prerm" "$BUILD_ROOT/DEBIAN/prerm"
install -m 0755 "$ROOT/packaging/deb/postrm" "$BUILD_ROOT/DEBIAN/postrm"

cat > "$BUILD_ROOT/DEBIAN/control" <<EOF
Package: $PACKAGE
Version: $VERSION
Section: net
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Description: $DESCRIPTION
EOF

install -d "$OUT_DIR"
dpkg-deb --root-owner-group --build "$BUILD_ROOT" "$OUT_DIR/${PACKAGE}_${VERSION}_${ARCH}.deb"
