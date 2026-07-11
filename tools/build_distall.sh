#!/usr/bin/env bash
# 組「完整可玩包」(含原始遊戲資源 + CHT + 執行檔)到 dist-all/。
# 版權:含遊戲資源,絕不上 GitHub/公開(dist-all/ 已 gitignore)。
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/dist-all"
rm -rf "$OUT"; mkdir -p "$OUT"

APPIMG_VGA="dist/packages/QFG1-CHT-VGA-x86_64.AppImage"
APPIMG_EGA="dist/packages/QFG1-CHT-EGA-x86_64.AppImage"
WINBIN="build/win-bin"

mk_linux(){ # $1 版本(VGA/EGA) $2 gamedir $3 appimage
  local v="$1" game="$2" img="$3"
  local d="$OUT/QFG1-CHT-${v}-linux"
  mkdir -p "$d/game"
  cp "$img" "$d/"
  cp -a "$game/." "$d/game/"
  cat > "$d/玩英雄傳奇I-繁中.sh" <<'SH'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$HERE"/*.AppImage 2>/dev/null || true
exec "$HERE"/*.AppImage --path="$HERE/game" --language=tw --auto-detect
SH
  chmod +x "$d/玩英雄傳奇I-繁中.sh"
  cat > "$d/README.txt" <<EOF
英雄傳奇 I 繁體中文化 — ${v} 完整可玩包(Linux)
執行:./玩英雄傳奇I-繁中.sh
(本包已含遊戲資源與中文化,直接可玩;僅供個人保存,勿散布。)
EOF
}

mk_windows(){ # $1 版本 $2 gamedir
  local v="$1" game="$2"
  local d="$OUT/QFG1-CHT-${v}-windows"
  mkdir -p "$d/game"
  cp "$WINBIN/scummvm.exe" "$WINBIN/SDL2.dll" "$WINBIN/libwinpthread-1.dll" "$d/"
  cp -a "$game/." "$d/game/"
  # bat(CRLF)
  printf '@echo off\r\ncd /d "%%~dp0"\r\nscummvm.exe --path="%%~dp0game" --language=tw --auto-detect\r\npause\r\n' > "$d/玩英雄傳奇I-繁中.bat"
  printf '英雄傳奇 I 繁體中文化 — %s 完整可玩包(Windows)\r\n雙擊 玩英雄傳奇I-繁中.bat 即可遊玩。\r\n(本包已含遊戲資源與中文化,僅供個人保存,勿散布。)\r\n' "$v" > "$d/README.txt"
}

echo ">> Linux VGA/EGA"
mk_linux VGA extract/vga_cht "$APPIMG_VGA"
mk_linux EGA extract/ega_cht "$APPIMG_EGA"
echo ">> Windows VGA/EGA"
mk_windows VGA extract/vga_cht
mk_windows EGA extract/ega_cht
echo ">> dev-setup"
cp dist/packages/qfg1-cht-dev-setup-*.tar.gz "$OUT/"

echo ">> === dist-all/ 產出 ==="
du -sh "$OUT"/* | sort -h

# ===== macOS 完整包(需先 gh run download macOS artifacts 到 build/mac-artifacts)=====
mk_macos(){ # $1 版本 $2 gamedir $3 tar.gz(含資料的 ScummVM.app)
  local v="$1" game="$2" tgz="$3"
  [ -f "$tgz" ] || { echo ">> (跳過 macOS $v:找不到 $tgz)"; return; }
  local d="$OUT/QFG1-CHT-${v}-macos"
  mkdir -p "$d/game"
  tar xzf "$tgz" -C "$d"                 # 解出 ScummVM.app
  cp -a "$game/." "$d/game/"
  cat > "$d/玩英雄傳奇I-繁中.command" <<'SH'
#!/bin/bash
cd "$(dirname "$0")"
xattr -dr com.apple.quarantine ./ScummVM.app 2>/dev/null || true
./ScummVM.app/Contents/MacOS/scummvm --path="./game" --language=tw --auto-detect
SH
  chmod +x "$d/玩英雄傳奇I-繁中.command"
  printf '英雄傳奇 I 繁體中文化 — %s 完整可玩包(macOS universal)\r\n雙擊 玩英雄傳奇I-繁中.command 遊玩(首次若被 Gatekeeper 擋,右鍵→打開)。\r\n(含遊戲資源,僅供個人保存,勿散布。)\r\n' "$v" > "$d/README.txt"
  echo ">> macOS $v -> $d"
}
MACART="$ROOT/build/mac-artifacts"
mk_macos VGA extract/vga_cht "$MACART/qfg1-cht-macos-vga/out-vga/QFG1-CHT-VGA-macos-universal.tar.gz"
mk_macos EGA extract/ega_cht "$MACART/qfg1-cht-macos-ega/out-ega/QFG1-CHT-EGA-macos-universal.tar.gz"
echo ">> === dist-all/ 最終 ==="; du -sh "$OUT"/* | sort -h
