# ImageMagick ARVO dataset image — one baseline tree at upstream 13ffeab, 61 patches.
#
# Build (context = the imagemagick-vul/ directory):
#   docker build -f image/Dockerfile -t imagemagick-vul:13ffeab .
#
# The base image supplies the 2018-era OSS-Fuzz toolchain (clang 6.0.0, libc++,
# the MSan libc++ in /usr/msan/lib, ImageMagick's build dependencies) and the
# full upstream history of ImageMagick.  That history stays in the image: the
# delivered tree is a real checkout of
#
#   13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a   7.0.7-21-82-g13ffeab, 2018-01-16
#
# with .git present and a clean work tree.  Nothing is patched into it: no
# prerequisite commit, no fixed tree, no refs.  The 61 fix patches live in
# /payload/patches and are applied to a copy at verify time (verify-one.sh).
#
#   /src/imagemagick   the baseline checkout, detached at 13ffeab, .git intact
#   /payload           63 cases, 63 PoCs, 61 standalone patches, vulnerabilities.json
#   /opt/imdt          lib.sh build.sh verify.sh verify-one.sh verify-one-by-one.sh
#   /out               repro-<fp>-<san>: the two baseline reproducers, prebuilt
#   /work              empty
FROM n132/arvo:42518038-vul@sha256:fce885bd28185e1f08512fad0085714b32526187f7041fb7941965e8fd8de124

SHELL ["/bin/bash", "-c"]

COPY payload/ /payload/
COPY scripts/ /opt/imdt/
COPY reports/ /opt/imdt/reports/

# The base image's WORKDIR is /src/imagemagick; move out of it so no RUN can
# recreate a directory we deleted.
WORKDIR /opt/imdt

# Pin the single tree and drop the base image's fuzzing tooling: this dataset
# ships a source tree and hand-written reproducers, not fuzz targets.
RUN set -eux; \
    chmod +x /opt/imdt/*.sh; \
    rm -rf /src/afl /src/honggfuzz /src/libfuzzer /src/afl_testcases.tgz /src/build.sh; \
    rm -rf /out/* /work/*; \
    cd /src/imagemagick; \
    git config gc.auto 0; \
    git checkout -q -f --detach 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    git reset -q --hard; \
    git clean -xffdq; \
    test "$(git rev-parse HEAD)" = 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    test "$(git log -1 --format='%ci')" = "2018-01-16 12:27:52 +0100"; \
    test -z "$(git status --porcelain)"

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
    source /opt/imdt/lib.sh; \
    for s in address memory; do ensure_repro "$TREE" "$s"; done; \
    rm -rf /work/*

# The delivered layout, asserted: one tree at the pinned commit with its history,
# no leftover fuzz tooling, the whole payload, the reproducers, an empty /work.
RUN set -eux; \
    source /opt/imdt/lib.sh; \
    test "$(ls /src)" = imagemagick; \
    test -d "$TREE/.git"; \
    test "$(baseline_commit)" = 13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a; \
    test -z "$(git -C "$TREE" status --porcelain)"; \
    test -f "$TREE/configure"; test -f "$TREE/MagickCore/image.c"; \
    for p in afl honggfuzz libfuzzer afl_testcases.tgz build.sh; do test ! -e "/src/$p"; done; \
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
