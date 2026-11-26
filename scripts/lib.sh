#!/bin/bash
# Shared helpers for the ImageMagick ARVO dataset: one baseline tree, one set of
# patches, one reproducer per (source fingerprint, sanitizer).
#
# /src/imagemagick          upstream 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a
#                           (7.0.7-21-82-g13ffeab, 2018-01-16), git repo, detached
# /payload                  cases.tsv, pocs/, patches/, vulnerabilities.json
# /out/repro-<fp>-<san>     instrumented reproducer, one per (fingerprint, sanitizer)
# /work/build-<fp>-<san>    private build; install prefix is <dir>/inst
#
# <fp> is the source fingerprint (commit + sha256 of `git diff`), so the baseline
# and every patched copy get their own cached build without collisions.
set -uo pipefail

IMDT_HOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TREE=${IMDT_TREE:-/src/imagemagick}
PAYLOAD=${PAYLOAD:-/payload}
OUT=${OUT:-/out}
WORK=${WORK:-/work}

die() { echo "error: $*" >&2; exit 1; }
ulimit -c 0 2>/dev/null || true   # a sanitizer crash must not leave core files

# One build per sanitizer — never merged (ASan+UBSan cross-talk makes unrelated
# UB elsewhere in the tree show up in every run).
san_profile() { case "$1" in
  address|asan) echo address ;; undefined|ubsan) echo undefined ;;
  memory|msan) echo memory ;; *) die "unknown sanitizer '$1' (address|undefined|memory)" ;;
esac; }

# The environment the OSS-Fuzz runner uses for each profile.
san_env() { case "$1" in
  address|asan) echo "ASAN_OPTIONS=allocator_may_return_null=1:detect_leaks=0:detect_container_overflow=1:detect_odr_violation=0:detect_stack_use_after_return=1:fast_unwind_on_fatal=0:handle_abort=1:handle_segv=1:handle_sigill=1:print_scariness=1:quarantine_size_mb=10:strict_memcmp=1:symbolize=1:use_sigaltstack=1:dedup_token_length=3" ;;
  undefined|ubsan) echo "UBSAN_OPTIONS=print_stacktrace=1:print_summary=1:symbolize=1:dedup_token_length=3" ;;
  memory|msan) echo "MSAN_OPTIONS=print_stats=1:symbolize=1:dedup_token_length=3" ;;
  *) die "unknown sanitizer '$1'" ;;
esac; }

san_flags() { case "$1" in
  address|asan) echo "-fsanitize=address -fsanitize-address-use-after-scope" ;;
  undefined|ubsan) echo "-fsanitize=undefined -fno-sanitize-recover=undefined" ;;
  memory|msan) echo "-fsanitize=memory -fsanitize-memory-track-origins" ;;
  *) die "unknown sanitizer '$1'" ;;
esac; }

# MSan needs the image's instrumented libc++ in /usr/msan/lib (the copy under
# /usr/local/lib is not instrumented).
san_link_extra() { [ "$(san_profile "$1")" = memory ] && echo "-L/usr/msan/lib"; return 0; }

# Source fingerprint <commit8>-<sha256(git diff)[:8]> of a git work tree.
src_fp() {
  local dir=$1 commit
  commit=$(git -C "$dir" rev-parse HEAD 2>/dev/null) || die "$dir is not a git work tree"
  printf '%s-%s' "${commit:0:8}" "$(git -C "$dir" diff | sha256sum | cut -c1-8)"
}

baseline_commit() { git -C "$TREE" rev-parse HEAD || die "$TREE is not a git work tree"; }

# run_poc <san> <binary> <coder> <poc> -> "<verdict><TAB><summary>"
#
#   CRASH  the sanitizer reported (`SUMMARY:` line) — the bug is present
#   CLEAN  exit status 0 and no report — the bug is gone
#   ERROR  neither: no report but the process did not exit 0
#
# MSan's runtime intermittently dies at startup with a bare SIGSEGV and no output
# (~15% of runs on this host, with or without setarch -R), which would look
# exactly like CLEAN.  Such a run is retried; a real crash always reports.
run_poc() {
  local san=$1 bin=$2 coder=$3 poc=$4 out sum rc try
  [ -x "$bin" ] || die "missing reproducer $bin (run: verify.sh)"
  [ -f "$poc" ] || die "missing PoC $poc"
  local envs; envs=$(san_env "$san")
  for try in 1 2 3 4 5 6 7 8 9 10; do
    if [ "$(san_profile "$san")" = memory ]; then
      out=$(setarch x86_64 -R env $envs "$bin" "$coder" "$poc" 2>&1) 2>/dev/null
    else
      out=$(env $envs "$bin" "$coder" "$poc" 2>&1) 2>/dev/null
    fi
    rc=$?
    sum=$(printf '%s\n' "$out" | grep -m1 '^SUMMARY: ' || true)
    if [ -n "$sum" ]; then printf 'CRASH\t%s\n' "$sum"; return 0; fi
    if [ "$rc" -eq 0 ]; then printf 'CLEAN\t-\n'; return 0; fi
  done
  printf 'ERROR\texit=%s\n' "$rc"
}

# ensure_repro <srcdir> <sanitizer> -> prints /out/repro-<fp>-<san>
#
# Copies the tree to /work/build-<fp>-<san>/src (never builds inside /src),
# configures with that sanitizer's flags, make -j, make install into ../inst,
# then links hand_repro.cc against the installed headers and static libs with the
# same instrumentation.  Progress goes to stderr; the binary path is the only
# thing on stdout, so callers can do bin=$(ensure_repro ...).  A finished
# /out/repro-<fp>-<san> is the cache: the fingerprint already encodes the source.
ensure_repro() {
  local dir=${1:?} s fp bld inst bin base sanflags cflags plain
  local pie ldp msan_libs conf_cflags
  s=$(san_profile "${2:?}")
  [ -d "$dir" ] || die "no such source tree: $dir"
  [ -f "$dir/configure" ] || die "$dir/configure missing (it is tracked; never regenerate)"
  fp=$(src_fp "$dir"); bld="$WORK/build-$fp-$s"; inst="$bld/inst"; bin="$OUT/repro-$fp-$s"
  if [ -x "$bin" ]; then echo "cached  $bin" >&2; printf '%s\n' "$bin"; return 0; fi

  base="-O1 -gline-tables-only -fno-omit-frame-pointer -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
  sanflags=$(san_flags "$s"); cflags="$base $sanflags"
  # Plain flags at configure time: an MSan-instrumented probe cannot run during
  # feature detection, so instrumentation is injected at make time only.
  plain="-O1 -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
  # 22.04 keeps delegate headers outside /usr/include (freetype2, openjpeg-2.4,
  # libxml2, uuid).  configure records them in Makefile's CFLAGS; overriding
  # CFLAGS outright would drop them, so keep that value and append the
  # sanitizer flags.  MSan also needs a PIE executable for its shadow mapping.
  pie=""; [ "$s" = memory ] && pie="-fPIE"
  ldp=""; [ "$s" = memory ] && ldp="-pie"
  # clang 14 on 22.04 adds -lc++ but not -lc++abi for -stdlib=libc++, and the
  # instrumented libc++.a needs cxa_* / typeinfo from libc++abi.a.
  msan_libs=""; [ "$s" = memory ] && msan_libs="-Wl,--start-group -lc++ -lc++abi -Wl,--end-group"

  rm -rf "$bld"; mkdir -p "$bld/src" "$OUT"
  ( cd "$dir" && tar -cf - --exclude=./.git . ) | ( cd "$bld/src" && tar -xf - ) ||
    die "cannot copy $dir"
  cd "$bld/src" || die "cannot enter $bld/src"
  # An in-tree plain build (build.sh) leaves Makefile, config.status and object
  # files behind: configure refuses to run next to config.status, and stale
  # objects would be reused with the wrong, non-instrumented flags.
  if [ -f Makefile ]; then make distclean > /dev/null 2>&1 || true; fi
  rm -f config.status config.log
  find . -name '*.o' -delete -o -name '*.lo' -delete

  echo "build   $dir [$s] -> $bld" >&2
  CC=clang CXX=clang++ CFLAGS="$plain" CXXFLAGS="$plain -stdlib=libc++" LDFLAGS="" \
    ./configure --prefix="$inst" --disable-shared --disable-docs \
    --disable-openmp --without-perl > "$bld/configure.log" 2>&1 ||
    { tail -n 6 "$bld/configure.log" >&2; die "configure failed ($fp/$s)"; }
  conf_cflags=$(sed -n 's/^CFLAGS = //p' Makefile | head -n 1)
  echo "make    $fp/$s" >&2
  make -j"$(nproc)" CFLAGS="$conf_cflags $sanflags $pie" CXXFLAGS="$conf_cflags $sanflags $pie -stdlib=libc++" LDFLAGS="$sanflags $ldp" \
    > "$bld/make.log" 2>&1 || { tail -n 20 "$bld/make.log" >&2; die "make failed ($fp/$s)"; }
  make install CFLAGS="$conf_cflags $sanflags $pie" CXXFLAGS="$conf_cflags $sanflags $pie -stdlib=libc++" LDFLAGS="$sanflags $ldp" \
    > "$bld/install.log" 2>&1 || { tail -n 20 "$bld/install.log" >&2; die "make install failed ($fp/$s)"; }

  echo "link    $bin" >&2
  clang++ $cflags $pie -stdlib=libc++ $(san_link_extra "$s") -std=c++11 \
    -I"$inst/include/ImageMagick-7" "$IMDT_HOME/hand_repro.cc" -o "$bin.new" \
    -DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 \
    "$inst/lib/libMagick++-7.Q16HDRI.a" "$inst/lib/libMagickWand-7.Q16HDRI.a" \
    "$inst/lib/libMagickCore-7.Q16HDRI.a" -lpthread $msan_libs -lm ||
    die "hand reproducer build failed ($fp/$s)"
  mv -f "$bin.new" "$bin"

  # The instrumentation must really be in the binary.  Grep a file, not nm's
  # output: `nm | grep -q` dies from SIGPIPE under pipefail.
  nm "$bin" > "$bld/nm.txt" 2>/dev/null || die "nm failed on $bin"
  case "$s" in
    address) grep -q '__asan_' "$bld/nm.txt" || die "$bin is not ASan-instrumented" ;;
    memory) grep -q '__msan_' "$bld/nm.txt" || die "$bin is not MSan-instrumented" ;;
    undefined) grep -q '__ubsan_' "$bld/nm.txt" || die "$bin is not UBSan-instrumented" ;;
  esac
  echo "built   $bin ($(stat -c %s "$bin") bytes, $s)" >&2
  printf '%s\n' "$bin"
}

# norm <CRASH|CLEAN|ERROR> -> crash|clean|error (the wording reports/ uses)
norm() { case "$1" in CRASH) echo crash ;; CLEAN) echo clean ;; *) echo error ;; esac; }
