#!/bin/bash
# The attribution run: every case with its own patch applied, one at a time.
#
#   verify-one-by-one.sh [--report DIR]          default report dir: reports
#
# For each of the 68 cases: apply exactly that case's patch to the baseline, build
# it, run that PoC.  `pass` is true when the sanitizer no longer reports, which is
# what all 68 entries and the top-level `pass` should be.  Writes
# DIR/verify-one-by-one.json (each entry also records its patch) and prints
# `pass=N fail=M`.  Costs one instrumented build per unique patch (62 patches for
# 68 cases) — about 100 minutes.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

report=reports
while [ $# -gt 0 ]; do case "$1" in
  --report) report=${2:?}; shift 2 ;;
  -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
  *) die "unknown argument: $1" ;;
esac; done

mkdir -p "$report" || die "cannot create $report"
scrap=$(mktemp -d); trap 'rm -rf "$scrap"' EXIT
rows="$scrap/rows"; : > "$rows"

pass=0; fail=0
while IFS=$'\t' read -r id _coder san alert _frame _poc patch _fc; do
  [ -n "$id" ] || continue
  if "$IMDT_HOME/verify-one.sh" "$id" --patched --report "$scrap" > "$scrap/out" 2>&1; then :; fi
  ok=$(awk -F'\t' '$1 == "RESULT" { print $3 }' "$scrap/out")
  [ -n "$ok" ] || ok=false
  if [ "$ok" = true ]; then verdict=PASS; pass=$((pass+1)); else verdict=FAIL; fail=$((fail+1)); fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "${patch##*/}" "$ok" "$san" "$alert" >> "$rows"
  printf '%-4s %-9s %s\n' "$verdict" "$id" "${patch##*/}"
done < <(awk -F'\t' '!/^#/ && NF >= 8' "$PAYLOAD/cases.tsv")

{
  printf '{"pass": %s, "fail": %s, "results": [\n' "$pass" "$fail"
  sep=""
  while IFS=$'\t' read -r id patch ok san alert; do
    printf '%s  {"poc": "%s", "patch": "%s", "pass": %s, "alert": "%s"}' \
      "$sep" "$id" "$patch" "$ok" "$alert"
    sep=$',\n'
  done < "$rows"
  printf '\n]}\n'
} > "$report/verify-one-by-one.json"

printf 'pass=%s fail=%s\n' "$pass" "$fail"
printf 'report: %s/verify-one-by-one.json\n' "$report"
[ "$fail" -eq 0 ]
