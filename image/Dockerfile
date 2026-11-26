# ImageMagick ARVO dataset image — Ubuntu 22.04 / glibc 2.35, one baseline tree
# at upstream 13ffeab, 61 patches.
#
# Build (context = the imagemagick-vul/ directory):
#   docker build -f image/Dockerfile -t imagemagick-vul:13ffeab .
#
# The image is built from ubuntu:22.04 and supplies its own MSan toolchain:
#
#   * clang 14 and the MSan runtime from Ubuntu jammy
#   * libc++/libc++abi 14.0.6 built *with* -fsanitize=memory into /usr/msan
#   * ImageMagick configured without delegate headers
#
# The delivered tree is a real checkout of
#
#   13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a   7.0.7-21-82-g13ffeab, 2018-01-16
#
# with .git present (single fetched commit, clean work tree).  Nothing is
# patched into it: no prerequisite commit, no fixed tree, no refs.  The 61 fix
# patches live in /payload/patches and are applied to a copy at verify time
# (verify-one.sh).
#
#   /src/imagemagick   the baseline checkout, detached at 13ffeab, .git intact
#   /payload           63 cases, 63 PoCs, 61 standalone patches, vulnerabilities.json
#   /opt/imdt          lib.sh build.sh verify.sh verify-one.sh verify-one-by-one.sh
#   /out               repro-<fp>-<san>: the two baseline reproducers, prebuilt
#   /work              empty
#
# In mainland China the default archive.ubuntu.com is often unusable; pass a
# mirror, for example:
#   --build-arg APT_MIRROR=http://repo.huaweicloud.com/ubuntu
#
# Set APT_PROXY only if the build container can reach that proxy; on Docker
# Desktop a proxy bound to the Windows host's 127.0.0.1 is not reachable from
# the Linux build VM.
#
# GitHub may also be unreachable from the build network.  Both source inputs
# can be overridden with a local mirror/HTTP server:
#   --build-arg LLVM_PROJECT_URL=http://host.docker.internal:8000/llvm-project-14.0.6.src.tar.xz
#   --build-arg IMAGEMAGICK_TARBALL_URL=http://host.docker.internal:8000/imagemagick-13ffeabe.tar.gz
#
# The resulting image needs --security-opt seccomp=unconfined at *run* time:
# MSan requires `setarch x86_64 -R`, and the default seccomp profile blocks
# personality(2).  The build itself only compiles and links.
FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

ARG APT_MIRROR=""
ARG APT_PROXY=""
ARG LLVM_PROJECT_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-project-14.0.6.src.tar.xz"
ARG IMAGEMAGICK_REPO="https://github.com/ImageMagick/ImageMagick.git"
ARG IMAGEMAGICK_TARBALL_URL=""
ARG IMAGEMAGICK_COMMIT="13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a"
ARG NORMALIZE_POCS="1"
ARG JOBS="4"

ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies only.  Deliberately no ImageMagick delegate -dev packages
# (freetype, jpeg, png, tiff, xml2, webp, openjpeg, lcms, fftw, zlib, bz2,
# lzma, jbig, ghostscript): the pinned 2018 baseline was built without them,
# and hand_repro.cc fails to link against a tree that suddenly has delegates.
RUN set -eux; \
    if [ -n "$APT_MIRROR" ]; then \
      sed -i "s|http://archive.ubuntu.com/ubuntu|$APT_MIRROR|g; \
              s|http://security.ubuntu.com/ubuntu|$APT_MIRROR|g" /etc/apt/sources.list; \
    fi; \
    if [ -n "$APT_PROXY" ]; then \
      printf 'Acquire::http::Proxy "%s";\nAcquire::https::Proxy "%s";\n' \
        "$APT_PROXY" "$APT_PROXY" > /etc/apt/apt.conf.d/99proxy; \
    fi; \
    apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=30 update; \
    apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=30 install -y --no-install-recommends \
      build-essential clang lld libc++-dev libc++abi-dev \
      libclang-common-14-dev cmake ninja-build git ca-certificates \
      curl wget xz-utils pkg-config autoconf automake libtool libltdl-dev \
      patch python3; \
    rm -f /etc/apt/apt.conf.d/99proxy; \
    rm -rf /var/lib/apt/lists/*

# MSan's libc++ must be instrumented; the distro libc++.a is not.  Build the
# standalone runtimes from the LLVM 14.0.6 sources.  The source tree also
# supplies llvm/cmake/modules for LLVM_PATH.
#
# libc++abi includes libc++'s headers from the source tree, so the generated
# __config_site must exist before that build starts.
RUN set -eux; \
    curl -fsSL --retry 3 "$LLVM_PROJECT_URL" -o /tmp/llvm-project.tar.xz; \
    mkdir -p /tmp/llvm-project; \
    tar -xJf /tmp/llvm-project.tar.xz -C /tmp/llvm-project --strip-components=1; \
    rm -f /tmp/llvm-project.tar.xz; \
    test -f /tmp/llvm-project/llvm/cmake/modules/AddLLVM.cmake; \
    test -d /tmp/llvm-project/libcxx; \
    test -d /tmp/llvm-project/libcxxabi; \
    : > /tmp/llvm-project/libcxx/include/__config_site

# Instrumented libc++abi first: libc++'s CMake links test programs against
# /usr/msan/lib/libc++abi.a.  LLVM_USE_SANITIZER=Memory alone is not honoured
# in standalone mode, so put -fsanitize=memory in the flags explicitly.
RUN set -eux; \
    runner() { if setarch x86_64 -R true 2>/dev/null; then setarch x86_64 -R "$@"; else "$@"; fi; }; \
    runner cmake -G Ninja -S /tmp/llvm-project/libcxxabi -B /tmp/build-abi \
      -DLLVM_PATH=/tmp/llvm-project/llvm \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/msan \
      -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_C_FLAGS="-fPIC -fsanitize=memory" \
      -DCMAKE_CXX_FLAGS="-fPIC -fsanitize=memory -fsanitize-memory-track-origins" \
      -DCMAKE_EXE_LINKER_FLAGS="-pie" \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_ENABLE_STATIC=ON \
      -DLIBCXXABI_USE_LLVM_UNWINDER=OFF \
      -DLIBCXXABI_LIBCXX_INCLUDES=/tmp/llvm-project/libcxx/include \
      > /tmp/abi-cmake.log 2>&1 || { tail -n 40 /tmp/abi-cmake.log; exit 1; }; \
    runner ninja -C /tmp/build-abi -j"$JOBS" > /tmp/abi-build.log 2>&1 || { tail -n 40 /tmp/abi-build.log; exit 1; }; \
    runner ninja -C /tmp/build-abi install > /tmp/abi-install.log 2>&1 || { tail -n 40 /tmp/abi-install.log; exit 1; }; \
    test "$(nm /usr/msan/lib/libc++abi.a | grep -c '__msan_')" -gt 0; \
    rm -rf /tmp/build-abi

# libc++ with the same MSan flags.  clang 14's -stdlib=libc++ links only
# -lc++, so scripts/lib.sh adds -lc++abi for the memory profile.
RUN set -eux; \
    runner() { if setarch x86_64 -R true 2>/dev/null; then setarch x86_64 -R "$@"; else "$@"; fi; }; \
    runner cmake -G Ninja -S /tmp/llvm-project/libcxx -B /tmp/build-cxx \
      -DLLVM_PATH=/tmp/llvm-project/llvm \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/msan \
      -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_C_FLAGS="-fPIC -fsanitize=memory" \
      -DCMAKE_CXX_FLAGS="-fPIC -fsanitize=memory -fsanitize-memory-track-origins" \
      -DCMAKE_EXE_LINKER_FLAGS="-pie -L/usr/msan/lib" \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_STATIC=ON \
      -DLIBCXX_CXX_ABI=libcxxabi \
      -DLIBCXX_CXX_ABI_INCLUDE_PATHS=/tmp/llvm-project/libcxxabi/include \
      -DLIBCXX_CXX_ABI_LIBRARY_PATH=/usr/msan/lib \
      -DLIBCXX_HAS_GCC_S_LIB=ON \
      > /tmp/cxx-cmake.log 2>&1 || { tail -n 40 /tmp/cxx-cmake.log; exit 1; }; \
    runner ninja -C /tmp/build-cxx -j"$JOBS" > /tmp/cxx-build.log 2>&1 || { tail -n 40 /tmp/cxx-build.log; exit 1; }; \
    runner ninja -C /tmp/build-cxx install > /tmp/cxx-install.log 2>&1 || { tail -n 40 /tmp/cxx-install.log; exit 1; }; \
    test "$(nm /usr/msan/lib/libc++.a | grep -c '__msan_')" -gt 0; \
    rm -rf /tmp/build-cxx /tmp/llvm-project

# The pinned ImageMagick tree, with .git intact: src_fp() needs the commit and
# a clean `git diff`.  A tarball containing the same checkout may be supplied
# for offline builds; otherwise fetch exactly one commit (no full history).
RUN set -eux; \
    git config --system core.autocrlf false; \
    mkdir -p /src; \
    if [ -n "$IMAGEMAGICK_TARBALL_URL" ]; then \
      curl -fsSL --retry 3 "$IMAGEMAGICK_TARBALL_URL" -o /tmp/imagemagick.tar.gz; \
      tar -xzf /tmp/imagemagick.tar.gz -C /src; \
      rm -f /tmp/imagemagick.tar.gz; \
    else \
      git init /src/imagemagick; \
      git -C /src/imagemagick remote add origin "$IMAGEMAGICK_REPO"; \
      git -C /src/imagemagick fetch --depth 1 origin "$IMAGEMAGICK_COMMIT"; \
      git -C /src/imagemagick checkout -f --detach FETCH_HEAD; \
    fi; \
    test -d /src/imagemagick/.git; \
    test "$(git -C /src/imagemagick rev-parse HEAD)" = "$IMAGEMAGICK_COMMIT"; \
    test -z "$(git -C /src/imagemagick status --porcelain)"

WORKDIR /opt/imdt

COPY payload/ /payload/
COPY scripts/ /opt/imdt/
COPY reports/ /opt/imdt/reports/

RUN set -eux; chmod +x /opt/imdt/*.sh

# The repository was checked out on Windows, where core.autocrlf turned six
# PoCs from LF into CRLF (the Git index still stores LF).  42530977's CRLF
# form is rejected by ReadHDRImage before the uninitialised read, producing a
# false CLEAN.  Restore the original LF bytes for those six files only; this
# is a byte-for-byte no-op on a Linux checkout.
RUN set -eux; \
    if [ "$NORMALIZE_POCS" = "1" ]; then \
      python3 -c 'from pathlib import Path; ids=("42518560","42519504","42520871","42522513","42530943","42530977"); [ (lambda p: p.write_bytes(p.read_bytes().replace(b"\r\n", b"\n")))(Path("/payload/pocs")/c/"poc") for c in ids ]'; \
    fi; \
    test "$(ls -d /payload/pocs/*/poc | wc -l)" = 63

ENV SRC=/src/imagemagick \
    PAYLOAD=/payload \
    OUT=/out \
    WORK=/work \
    PATH=/opt/imdt:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/out

# Prebuild the baseline reproducers every shipped case needs, so the image
# verifies out of the box: /out/repro-<fp>-<san>, hand_repro.cc linked against
# that build's installed headers and static libs.  hand_repro.cc is a
# hand-written driver (no fuzz target, no libFuzzer runtime): forced coder on the
# command line, Blob read + write back, swallowed Magick::Exception.  No case
# uses UBSan, but lib.sh still accepts `undefined` for a tree that needs it.
# /work is emptied in the same layer, so verify-one still runs real builds.
RUN set -eux; \
    mkdir -p "$OUT" "$WORK"; \
    source /opt/imdt/lib.sh; \
    for s in address memory; do ensure_repro "$TREE" "$s"; done; \
    rm -rf "$WORK"/*

# The delivered layout, asserted: one tree at the pinned commit, the whole
# payload, the reproducers, an empty /work.
RUN set -eux; \
    source /opt/imdt/lib.sh; \
    test "$(ls /src)" = imagemagick; \
    test -d "$TREE/.git"; \
    test "$(baseline_commit)" = 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    test -z "$(git -C "$TREE" status --porcelain)"; \
    test -f "$TREE/configure"; test -f "$TREE/MagickCore/image.c"; \
    test "$(ls /payload/patches/*.patch | wc -l)" = 61; \
    test ! -e /payload/patches/resolved; \
    test ! -e /payload/vulnerabilities.csv; \
    test ! -e /payload/vulnerabilities.md; \
    test "$(ls -d /payload/pocs/*/poc | wc -l)" = 63; \
    test "$(awk -F'\t' '!/^#/ && NF >= 8' /payload/cases.tsv | wc -l)" = 63; \
    test ! -e /opt/imdt/build-san.sh; \
    test "$(ls /out | wc -l)" = 2; \
    for s in address memory; do test -x "/out/repro-$(src_fp "$TREE")-$s"; done; \
    test -z "$(ls -A /work)"

CMD ["/bin/bash"]
