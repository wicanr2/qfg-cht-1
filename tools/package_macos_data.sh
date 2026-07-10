#!/usr/bin/env bash
# 把 macOS CI(.github/workflows/build-macos.yml)產出的「空引擎」ScummVM.app,
# 注入中文資料(translation.tsv + qfg1_big5.fnt + VGA view/pic patch)+ README,
# 重新打包成可交付檔。在 CI runner 內跑(bash 內建即可,不需 docker/python)。
#
# 用法:tools/package_macos_data.sh <engine.tar.gz 或 .app 路徑> <vga|ega> <輸出目錄>
#
# 交付原則(硬):.app 本身只含 patched 引擎;中文資料放進
# .app/Contents/Resources/cht-data-<edition>/,原遊戲資源絕不塞入。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:?用法: package_macos_data.sh <engine.tar.gz|.app> <vga|ega> <輸出目錄>}"
EDITION="${2:?edition 需為 vga 或 ega}"
OUT="${3:?需指定輸出目錄}"

case "$EDITION" in vga|ega) ;; *) echo "!! edition 需為 vga 或 ega,收到:$EDITION" >&2; exit 1 ;; esac

source "$ROOT/tools/pkg_common.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 接受 .tar.gz 或已展開的 .app 兩種輸入
if [ -d "$SRC" ] && [[ "$SRC" == *.app ]]; then
  cp -R "$SRC" "$WORK/ScummVM.app"
else
  tar xzf "$SRC" -C "$WORK"
fi
APP="$(find "$WORK" -maxdepth 2 -iname '*.app' -type d | head -1)"
[ -n "$APP" ] || { echo "!! 在 $SRC 裡找不到 .app" >&2; exit 1; }

echo ">> 注入 $EDITION 中文資料 → $APP/Contents/Resources/cht-data-${EDITION}/"
stage_cht_data "$EDITION" "$APP/Contents/Resources/cht-data-${EDITION}"
gen_readme "$EDITION" macos > "$APP/Contents/Resources/README-cht.txt"

# 重簽:Resources 內容變動後,原本 build 期的 ad-hoc 簽章需要重蓋(--deep 涵蓋巢狀 dylib)
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" 2>/dev/null || echo "!! codesign 失敗(非 macOS host 執行屬預期,CI runner 上應成功)"
fi

mkdir -p "$OUT"
LABEL="QFG1-CHT-$(echo "$EDITION" | tr '[:lower:]' '[:upper:]')-macos-universal"
tar czf "$OUT/${LABEL}.tar.gz" -C "$(dirname "$APP")" "$(basename "$APP")"
echo ">> -> $OUT/${LABEL}.tar.gz"

if command -v hdiutil >/dev/null 2>&1; then
  hdiutil create -volname "$LABEL" -srcfolder "$APP" -ov -format UDZO "$OUT/${LABEL}.dmg"
  echo ">> -> $OUT/${LABEL}.dmg"
else
  echo ">> (非 macOS host,略過 .dmg——hdiutil 只在 macOS 存在;CI runner 上會產出)"
fi

ls -la "$OUT"
