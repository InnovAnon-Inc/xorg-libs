#! /bin/bash
set -euvxo pipefail
(( UID ))
(( $# >= 1 ))
URL="$1"
shift
if (( ! $# )) ; then
  PKG="${URL/.git/}"
  PKG="$(basename "$PKG")"
else
  PKG="$1"
  shift
fi
(( ! $# ))
[[ "$URL" ]]
[[ "$PKG" ]]
sleep 31
git clone --depth=1 --recursive "$URL"
cd                "$PKG"
./autogen.sh
# shellcheck disable=SC2086
./configure $XORG_CONFIG
make
make "DESTDIR=/tmp/$PKG" install
cd                  ..
rm -rf            "$PKG"
cd           "/tmp/$PKG"
strip.sh .
tar acf      "/tmp/$PKG.txz" .
cd                  ..
rm -rf       "/tmp/$PKG"

