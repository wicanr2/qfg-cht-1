#!/usr/bin/env bash
# 把繁中化引擎改動套進一份乾淨(或既有)的 ScummVM source 樹。
# 用法:apply_patches.sh <scummvm-src-dir>
set -euo pipefail
SRC="${1:?用法: apply_patches.sh <scummvm-src-dir>}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

# 新檔
cp "$HERE/patches/fontchinese.h"   "$SRC/engines/sci/graphics/fontchinese.h"
cp "$HERE/patches/fontchinese.cpp" "$SRC/engines/sci/graphics/fontchinese.cpp"

# 既有檔 diff
patch -p0 -d "$SRC" < "$HERE/patches/0001-sci-cht-zh_twn.patch"

echo ">> 已套用。configure 範例(docker 內):"
echo "   ./configure --disable-all-engines --enable-engine=sci --disable-detection-full --disable-mt32emu"
