#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR=$(cd "$(dirname "$0")" && pwd)
BASEDIR=$(cd "$SCRIPTDIR/.." && pwd)
DISTDIR="$BASEDIR/dist/pkg"
TMPDIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

VERSION_SUFFIX=""
if [ $# -gt 0 ]; then
    VERSION_SUFFIX="-$1"
fi

( cd "$BASEDIR" && npm run build:pkg:all )

mkdir -p "$DISTDIR"

ZIP_TARGETS=(
    "quicktype-macos-arm64:quicktype${VERSION_SUFFIX}-macos-arm64.zip:quicktype"
    "quicktype-linux-x64:quicktype${VERSION_SUFFIX}-linux-x64.zip:quicktype"
    "quicktype-linux-arm64:quicktype${VERSION_SUFFIX}-linux-arm64.zip:quicktype"
    "quicktype-win-x64.exe:quicktype${VERSION_SUFFIX}-win-x64.zip:quicktype.exe"
)

for entry in "${ZIP_TARGETS[@]}"; do
    IFS=":" read -r source zipname binname <<< "$entry"
    srcpath="$BASEDIR/dist/$source"
    outdir="$TMPDIR/$zipname"
    outfile="$outdir/$binname"

    if [ ! -f "$srcpath" ]; then
        echo "Missing expected binary: $srcpath" >&2
        exit 1
    fi

    mkdir -p "$outdir"
    cp "$srcpath" "$outfile"
    zip -j "$DISTDIR/$zipname" "$outfile" >/dev/null
    echo "Wrote $DISTDIR/$zipname"
done

echo "SHA512 sums:"
if command -v sha512sum >/dev/null 2>&1; then
    sha512sum "$DISTDIR"/quicktype-*.zip
else
    shasum -a 512 "$DISTDIR"/quicktype-*.zip
fi
