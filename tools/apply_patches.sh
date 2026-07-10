#!/usr/bin/env bash
# 把繁中化引擎改動套進一份乾淨(或既有)的 ScummVM source 樹。
#
# 用法:apply_patches.sh <scummvm-src-dir>
#   - 若 <scummvm-src-dir> 不存在:自動 clone 官方 scummvm/scummvm,
#     checkout patches/UPSTREAM_COMMIT.txt 記錄的 pinned commit(依 dists/ 檔案時間戳用
#     GitHub API 反推的本專案開發時期版本,非逐字記錄的原始 checkout——上游若已大幅
#     drift,下方 patch 套用步驟會直接失敗並停止,不會默默套錯)。
#   - 若 <scummvm-src-dir> 已存在(本機既有 checkout):直接對它套用,不會動 git 狀態。
set -euo pipefail
SRC="${1:?用法: apply_patches.sh <scummvm-src-dir>}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$SRC" ]; then
  UPSTREAM="$(cat "$HERE/patches/UPSTREAM_COMMIT.txt")"
  echo ">> $SRC 不存在,clone 官方 ScummVM @ $UPSTREAM"
  # core.autocrlf=false:Windows(MSYS2)預設 autocrlf=true 會把 patch 轉 CRLF 導致套不上
  git clone --config core.autocrlf=false --config core.eol=lf https://github.com/scummvm/scummvm.git "$SRC"
  git -C "$SRC" fetch --depth 1 origin "$UPSTREAM" 2>/dev/null || git -C "$SRC" fetch origin
  git -C "$SRC" checkout -f "$UPSTREAM"
fi

# 新檔
cp "$HERE/patches/fontchinese.h"   "$SRC/engines/sci/graphics/fontchinese.h"
cp "$HERE/patches/fontchinese.cpp" "$SRC/engines/sci/graphics/fontchinese.cpp"

# 既有檔 diff
patch -p0 -d "$SRC" < "$HERE/patches/0001-sci-cht-zh_twn.patch"

echo ">> 已套用。configure 範例(docker 內):"
echo "   ./configure --disable-all-engines --enable-engine=sci --disable-detection-full --disable-mt32emu"
