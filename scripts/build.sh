#!/bin/bash
# Plain (non-instrumented) build of the baseline tree — no sanitizer, no
# reproducer, just the project's own configure and make.  This is the build a
# static-analysis or repair tool can drive.
#
#   build.sh [--tree DIR]         default: /src/imagemagick
#
# In-tree, so <DIR>/utilities/magick appears.  Re-running is cheap: configure is
# skipped once a Makefile exists, and make is incremental.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

dir=$TREE
while [ $# -gt 0 ]; do
  case $1 in
    --tree) dir=${2:?--tree needs a directory}; shift 2 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    -*) die "unknown argument $1" ;;
    *) dir=$1; shift ;;
  esac
done
[ -d "$dir" ] || die "no such directory: $dir"
[ -f "$dir/configure" ] || die "$dir/configure missing (it is tracked; never regenerate)"
start=$(date +%s)
cd "$dir"
if [ ! -f Makefile ]; then
  echo "== configure $dir"
  CC=clang CXX=clang++ ./configure --disable-shared --disable-docs \
    --disable-openmp --without-perl > /tmp/plain-configure.log 2>&1 ||
    { tail -n 6 /tmp/plain-configure.log; die "configure failed in $dir"; }
fi
echo "== make $dir"
make -j"$(nproc)" > /tmp/plain-make.log 2>&1 ||
  { tail -n 20 /tmp/plain-make.log; die "make failed in $dir"; }
[ -x utilities/magick ] || die "no utilities/magick after make in $dir"
echo "built $dir/utilities/magick ($(( $(date +%s) - start ))s) — $(utilities/magick -version | sed -n 1p)"
