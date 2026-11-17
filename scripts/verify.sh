#!/bin/bash
# Every case of /payload/cases.tsv against one source tree — by default the
# baseline shipped with this dataset — i.e. `verify-one.sh` looped over every PoC.
#
#   verify.sh [--report DIR] [--tree DIR]
#
# --tree DIR — source tree to test; default /src/imagemagick (or $IMDT_TREE).
# One line per case, then `clean=N crash=M`.  No patches are applied, so every
# PoC is expected to crash: `pass` is false for every entry, and the top-level
# `pass` is false too.  That is the point — the baseline still has the bugs.
#
# Exit status is non-zero when a PoC comes back CLEAN (it no longer crashes the
# tree under test), because a silent change there would make every downstream
# "is it fixed?" answer meaningless.  ERROR runs are counted as crash here; see
# the limitations in README.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

report=reports; src=$TREE
while [ $# -gt 0 ]; do case "$1" in
  --report) report=${2:?}; shift 2 ;;
  --tree) src=${2:?}; shift 2 ;;
  -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
  *) die "unknown argument: $1" ;;
esac; done
[ -d "$src" ] || die "no such source tree: $src"

mkdir -p "$report" || die "cannot create $report"
scrap=$(mktemp -d); trap 'rm -rf "$scrap"' EXIT
rows="$scrap/rows"; : > "$rows"

clean=0; crash=0
while IFS=$'\t' read -r id _coder san alert _frame _poc _patch _fc; do
  [ -n "$id" ] || continue
  if "$IMDT_HOME/verify-one.sh" "$id" --tree "$src" --report "$scrap" > "$scrap/out" 2>&1; then :; fi
  pass=$(awk -F'\t' '$1 == "RESULT" { print $3 }' "$scrap/out")
  [ -n "$pass" ] || pass=false
  if [ "$pass" = true ]; then verdict=CLEAN; clean=$((clean+1)); else verdict=CRASH; crash=$((crash+1)); fi
  printf '%s\t%s\t%s\t%s\n' "$id" "$pass" "$san" "$alert" >> "$rows"
  printf '%-5s %-9s %-6s %-9s %s\n' "$verdict" "$id" "$_coder" "$san" "$alert"
done < <(awk -F'\t' '!/^#/ && NF >= 8' "$PAYLOAD/cases.tsv")

{
  printf '{"pass": %s, "fail": %s, "results": [\n' "$clean" "$crash"
  sep=""
  while IFS=$'\t' read -r id pass san alert; do
    printf '%s  {"poc": "%s", "pass": %s, "alert": "%s"}' \
      "$sep" "$id" "$pass" "$alert"
    sep=$',\n'
  done < "$rows"
  printf '\n]}\n'
} > "$report/verify.json"

printf 'clean=%s crash=%s\n' "$clean" "$crash"
printf 'report: %s/verify.json\n' "$report"
[ "$clean" -eq 0 ]
