#!/bin/bash
# One case, on one tree: the baseline (default) or the baseline plus that case's
# patch (--patched).
#
#   verify-one.sh <pocId> [--patched] [--report DIR] [--keep]   default dir: reports
#
# Default — the tree the dataset ships: build (cached) and run that case's PoC.
#   The bug is still there, so the sanitizer reports and pass is false.
# --patched — copy /src/imagemagick to /work/one-<localId>, git apply that case's
#   patch (nothing else), build, run the same PoC.  pass is true when the saniti-
#   zer no longer reports.
#
# `pass` means the same thing in every report this package writes: **the PoC did
# not crash the tree under test**.  Baseline -> false, patched -> true.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

report=reports; ID=""; keep=0; patched=0
while [ $# -gt 0 ]; do case "$1" in
  --report) report=${2:?}; shift 2 ;;
  --patched) patched=1; shift ;;
  --keep) keep=1; shift ;;
  -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
  -*) die "unknown argument: $1" ;;
  *) [ -z "$ID" ] || die "only one pocId at a time"; ID=$1; shift ;;
esac; done
[ -n "$ID" ] || die "usage: verify-one.sh <pocId> [--patched] [--report DIR] [--keep]"

row=$(awk -F'\t' -v id="$ID" '!/^#/ && $1 == id { print; exit }' "$PAYLOAD/cases.tsv")
[ -n "$row" ] || die "case '$ID' not found in $PAYLOAD/cases.tsv"
coder=$(printf '%s\n' "$row" | cut -f2)
san=$(printf '%s\n' "$row" | cut -f3)
alert=$(printf '%s\n' "$row" | cut -f4)
poc=$(printf '%s\n' "$row" | cut -f6)
patch_file="$PAYLOAD/$(printf '%s\n' "$row" | cut -f7)"
patch=${patch_file#"$PAYLOAD/"}

tree="$TREE"; work=""
if [ "$patched" -eq 1 ]; then
  [ -f "$patch_file" ] || die "patch not found: $patch_file"
  work="$WORK/one-$ID"
  rm -rf "$work"; mkdir -p "$work" || die "cannot create $work"
  cp -a "$TREE/." "$work/" || die "cannot copy $TREE"
  git -C "$work" apply --check "$patch_file" || die "does not apply to the baseline: $patch"
  git -C "$work" apply "$patch_file" || die "git apply failed: $patch"
  tree="$work"
  patched_fp=$(src_fp "$work")
fi

bin=$(ensure_repro "$tree" "$san") || exit 1
res=$(norm "$(run_poc "$san" "$bin" "$coder" "$PAYLOAD/$poc" | cut -f1)")

pass=false; [ "$res" = clean ] && pass=true
verdict=CLEAN; [ "$pass" = true ] || verdict=CRASH

mkdir -p "$report" || die "cannot create $report"
json="$report/verify-one.json"
{
  printf '{"pass": %s, "fail": %s, "results": [\n' \
    "$([ "$pass" = true ] && echo 1 || echo 0)" "$([ "$pass" = true ] && echo 0 || echo 1)"
  printf '  {"poc": "%s", "pass": %s, "alert": "%s"}' \
    "$ID" "$pass" "$alert"
  printf '\n]}\n'
} > "$json.tmp" && mv -f "$json.tmp" "$json"

printf 'RESULT\t%s\t%s\t%s\t%s\n' "$ID" "$pass" "$alert"
printf '%-9s %-5s %-6s %-9s %s\n' "$ID" "$verdict" "$coder" "$san" \
  "$([ "$patched" -eq 1 ] && echo "baseline + ${patch#patches/}" || echo baseline)"
printf 'report  %s\n' "$json"
if [ -n "$work" ] && [ "$keep" -eq 0 ]; then rm -rf "$work" "$WORK/build-$patched_fp-$san"; fi
[ "$pass" = "$([ "$patched" -eq 1 ] && echo true || echo false)" ]
