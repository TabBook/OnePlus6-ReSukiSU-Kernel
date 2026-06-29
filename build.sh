#!/usr/bin/env bash
#
# Build script for the ReSukiSU Kernel for OnePlus 6 (enchilada).
# Reproduces the v3 build: LineageOS 4.9 + ReSukiSU manual hook.
#
# Requirements:
#   - Neutron Clang (or AOSP clang) in $CLANG_DIR
#   - aarch64 GNU binutils providing the aarch64-linux-gnu- CROSS_COMPILE
#   - bc bison flex openssl git zip ccache python cpio dtc
#
# Do NOT use LLVM=1 / the integrated assembler on this 4.9 kernel.
set -euo pipefail

# ---- pinned sources (v3) ----
KERNEL_REPO="https://github.com/LineageOS/android_kernel_oneplus_sdm845"
KERNEL_BRANCH="lineage-22.2"
KERNEL_COMMIT="2e921a892c03b8a17b4d82e9b24c2b3aa775c870"
RESUKISU_SETUP="https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh"
RESUKISU_REF="a4f7744c"   # ReSukiSU v4.1.0-… used for v3

# ---- paths (edit CLANG_DIR to your toolchain) ----
ROOT="$(pwd)"
CLANG_DIR="${CLANG_DIR:-$ROOT/clang}"
KSRC="$ROOT/kernel"

export ARCH=arm64 SUBARCH=arm64
export KBUILD_BUILD_USER=VoL KBUILD_BUILD_HOST=archwsl
export PATH="$CLANG_DIR/bin:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu-

# clang-23 promotes some benign casts to -Werror on old Qualcomm code; downgrade
# them (no logic change) so the build proceeds.
KCFLAGS="-Wno-default-const-init-unsafe -Wno-default-const-init-field-unsafe \
-Wno-default-const-init-var-unsafe -Wno-error=implicit-enum-enum-cast \
-Wno-error=implicit-int-enum-cast -Wno-error=enum-enum-conversion \
-Wno-error=enum-conversion"

# 1. source
if [ ! -d "$KSRC" ]; then
  git clone --depth=1 -b "$KERNEL_BRANCH" "$KERNEL_REPO" "$KSRC"
fi
cd "$KSRC"

# 2. ReSukiSU (manual hook)
[ -d KernelSU ] || curl -LSs "$RESUKISU_SETUP" | bash -s "$RESUKISU_REF"

# 3. patches
git apply "$ROOT/patches/0001-resukisu-manual-hooks.patch" || true
git apply "$ROOT/patches/0002-enchilada-defconfig.patch"   || true
cp "$ROOT/patches/set_memory.h" arch/arm64/include/asm/set_memory.h

# 4. build
make O=out ARCH=arm64 enchilada_defconfig
make -j"$(nproc)" O=out ARCH=arm64 CC="ccache clang" \
     CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- \
     KCFLAGS="$KCFLAGS" Image.gz-dtb

echo "==> out/arch/arm64/boot/Image.gz-dtb"
echo "Pack it into AnyKernel3 (see anykernel/anykernel.sh) to get a flashable zip."
