#!/usr/bin/env bash
# 組「完整可玩包」到 dist-all/,產出「壓縮 / 直接可執行」的交付形式:
#   - Linux : full self-contained AppImage —— 遊戲資源 + 中文化內嵌,`./QFG1-*.AppImage` 直接進繁中遊戲(免腳本、免分離 game/)
#   - Windows: QFG1-*-windows-full.zip —— scummvm.exe + DLL + game/ + .bat 啟動器
#   - macOS  : QFG1-*-macos-full.zip —— ScummVM.app + game/ + .command 啟動器(zip -y 保留 .app 內 symlink)
# 版權:含遊戲資源,絕不上 GitHub/公開(dist-all/ 已 gitignore),僅本機私人保留。
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/dist-all"
rm -rf "$OUT"; mkdir -p "$OUT"

APPIMG_VGA="dist/packages/QFG1-CHT-VGA-x86_64.AppImage"   # slim(patch-only)當基底
APPIMG_EGA="dist/packages/QFG1-CHT-EGA-x86_64.AppImage"
WINBIN="build/win-bin"
APPIMAGETOOL="tools/.cache/appimagetool-x86_64.AppImage"

# ---- Linux: full self-contained AppImage(遊戲內嵌 + AppRun 自動帶 --path/--language) ----
mk_appimage_full(){ # $1 版本(VGA/EGA) $2 gamedir $3 slim_appimage
  local v="$1" game="$2" slim="$3"
  local work="$ROOT/build/appimg-full-$v"
  echo ">> [Linux] full AppImage $v"
  rm -rf "$work"; mkdir -p "$work"; ( cd "$work" && "$ROOT/$slim" --appimage-extract >/dev/null )
  local sq="$work/squashfs-root"
  mkdir -p "$sq/usr/share/game"
  cp -a "$ROOT/$game/." "$sq/usr/share/game/"
  # AppRun:直接啟動內嵌遊戲(繁中),仍容許附加參數
  cat > "$sq/AppRun" <<'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/usr/bin/scummvm" --path="$HERE/usr/share/game" --language=tw --auto-detect "$@"
APPRUN
  chmod +x "$sq/AppRun"
  local out="$OUT/QFG1-CHT-${v}-full-x86_64.AppImage"
  # appimagetool 需 `file` 判 ELF;qfg1-build 沒裝,現場裝(隨 --rm 即棄)
  docker run --rm -v "$work:/w" -v "$ROOT/$(dirname "$APPIMAGETOOL"):/tools:ro" -e ARCH=x86_64 -w /w \
    qfg1-build bash -c "apt-get update -qq >/dev/null && apt-get install -y -qq file >/dev/null && \
      /tools/$(basename "$APPIMAGETOOL") --appimage-extract-and-run squashfs-root /w/out.AppImage" >/dev/null
  mv "$work/out.AppImage" "$out"
  chmod +x "$out" 2>/dev/null || true
  rm -rf "$work"
  echo "   -> $out ($(du -h "$out" | cut -f1))  # ./$(basename "$out") 直接可玩"
}

# ---- Windows: 完整包 zip ----
mk_windows_zip(){ # $1 版本 $2 gamedir
  local v="$1" game="$2"
  local stage="$ROOT/build/win-full-$v/QFG1-CHT-${v}-windows"
  echo ">> [Windows] zip $v"
  rm -rf "$(dirname "$stage")"; mkdir -p "$stage/game"
  cp "$WINBIN/scummvm.exe" "$WINBIN/SDL2.dll" "$WINBIN/libwinpthread-1.dll" "$stage/"
  cp -a "$game/." "$stage/game/"
  printf '@echo off\r\ncd /d "%%~dp0"\r\nscummvm.exe --path="%%~dp0game" --language=tw --auto-detect\r\npause\r\n' > "$stage/玩英雄傳奇I-繁中.bat"
  printf '英雄傳奇 I 繁體中文化 — %s 完整可玩包(Windows)\r\n雙擊 玩英雄傳奇I-繁中.bat 即可遊玩。\r\n(本包已含遊戲資源與中文化,僅供個人保存,勿散布。)\r\n' "$v" > "$stage/README.txt"
  local out="$OUT/QFG1-CHT-${v}-windows-full.zip"
  ( cd "$(dirname "$stage")" && zip -qr "$out" "$(basename "$stage")" )
  rm -rf "$(dirname "$stage")"
  echo "   -> $out ($(du -h "$out" | cut -f1))"
}

# ---- macOS: 完整包 zip(需先有 CI 產的含資料 .app tar.gz)----
mk_macos_zip(){ # $1 版本 $2 gamedir $3 tar.gz(ScummVM.app)
  local v="$1" game="$2" tgz="$3"
  [ -f "$tgz" ] || { echo ">> [macOS] 跳過 $v(找不到 $tgz)"; return; }
  local stage="$ROOT/build/mac-full-$v/QFG1-CHT-${v}-macos"
  echo ">> [macOS] zip $v"
  rm -rf "$(dirname "$stage")"; mkdir -p "$stage/game"
  tar xzf "$tgz" -C "$stage"                 # 解出 ScummVM.app
  cp -a "$game/." "$stage/game/"
  cat > "$stage/玩英雄傳奇I-繁中.command" <<'SH'
#!/bin/bash
cd "$(dirname "$0")"
xattr -dr com.apple.quarantine ./ScummVM.app 2>/dev/null || true
./ScummVM.app/Contents/MacOS/scummvm --path="./game" --language=tw --auto-detect
SH
  chmod +x "$stage/玩英雄傳奇I-繁中.command"
  printf '英雄傳奇 I 繁體中文化 — %s 完整可玩包(macOS universal)\n雙擊 玩英雄傳奇I-繁中.command 遊玩(首次若被 Gatekeeper 擋,右鍵→打開)。\n(含遊戲資源,僅供個人保存,勿散布。)\n' "$v" > "$stage/README.txt"
  local out="$OUT/QFG1-CHT-${v}-macos-full.zip"
  # -y 保留 .app 內 symlink(Frameworks/Versions);Linux 製 zip 在 macOS 解出仍可用
  ( cd "$(dirname "$stage")" && zip -qry "$out" "$(basename "$stage")" )
  rm -rf "$(dirname "$stage")"
  echo "   -> $out ($(du -h "$out" | cut -f1))"
}

echo "===== dist-all/ 完整可玩包(壓縮 / 直接執行)====="
mk_appimage_full VGA extract/vga_cht "$APPIMG_VGA"
mk_appimage_full EGA extract/ega_cht "$APPIMG_EGA"
mk_windows_zip   VGA extract/vga_cht
mk_windows_zip   EGA extract/ega_cht
MACART="$ROOT/build/mac-artifacts"
mk_macos_zip VGA extract/vga_cht "$MACART/qfg1-cht-macos-vga/out-vga/QFG1-CHT-VGA-macos-universal.tar.gz"
mk_macos_zip EGA extract/ega_cht "$MACART/qfg1-cht-macos-ega/out-ega/QFG1-CHT-EGA-macos-universal.tar.gz"
echo ">> dev-setup"
cp dist/packages/qfg1-cht-dev-setup-*.tar.gz "$OUT/" 2>/dev/null || true

echo ""
echo "===== dist-all/ 產出 ====="
ls -la "$OUT" | grep -v '^total\|^總用量'
