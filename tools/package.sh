#!/usr/bin/env bash
# 英雄傳奇 I 繁中化 — 一鍵組裝本機可做的交付檔(AppImage x2、Windows zip x2、dev-setup tar.gz)。
#
# 交付原則(硬,見 CLAUDE.md / WORKLIST.md):中文化僅放 ScummVM patch——
# patched 引擎 + 中文資料(translation.tsv + qfg1_big5.fnt + VGA view/pic patch)+ README。
# 原遊戲資源(RESOURCE.* 等)絕不入包,使用者自備合法遊戲檔。
#
# 用法:tools/package.sh            # 全部(appimage + windows + dev-setup)
#       tools/package.sh appimage   # 只做 Linux AppImage
#       tools/package.sh windows    # 只做 Windows zip
#       tools/package.sh dev-setup  # 只做 dev-setup tar.gz
#
# 依賴:docker(qfg1-build / qfg1-capture / qfg1-mingw image 需已 build)、host 的 zip/tar。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist/packages"
STAGE="$ROOT/build/pkg-stage"
DATE_TAG="$(date +%Y%m%d)"

log() { echo ">> $*"; }
die() { echo "!! $*" >&2; exit 1; }

mkdir -p "$DIST" "$STAGE"
source "$ROOT/tools/pkg_common.sh"   # stage_cht_data() / gen_readme()(與 package_macos_data.sh 共用)

# ---------------------------------------------------------------------------
# 0) 重建 VGA / EGA 中文資料(translation.tsv + qfg1_big5.fnt),確保跟 translation/ 原始碼同步
# ---------------------------------------------------------------------------
UMING_FONT="/usr/share/fonts/truetype/arphic/uming.ttc"

rebuild_cht_data() {
  log "重建中文資料(build_cht.py):VGA → dist/、EGA → dist_ega/"
  [ -f "$UMING_FONT" ] || die "找不到 $UMING_FONT(host 需裝 fonts-arphic-uming,build_cht.py 烘字要用)"
  docker run --rm \
    -v "$ROOT/tools:/w/tools" -v "$ROOT/translation:/w/translation" -v "$ROOT/dist:/w/dist" \
    -v "$UMING_FONT:$UMING_FONT:ro" \
    -w /w ghcr.io/astral-sh/uv:python3.12-bookworm-slim \
    uv run --quiet --with pillow tools/build_cht.py translation/translation.tsv dist
  docker run --rm \
    -v "$ROOT/tools:/w/tools" -v "$ROOT/translation:/w/translation" -v "$ROOT/dist_ega:/w/dist_ega" \
    -v "$UMING_FONT:$UMING_FONT:ro" \
    -w /w ghcr.io/astral-sh/uv:python3.12-bookworm-slim \
    uv run --quiet --with pillow tools/build_cht.py translation/ega/translation.tsv dist_ega
}

# ---------------------------------------------------------------------------
# 1) Linux AppImage(手工 AppDir + appimagetool,--appimage-extract-and-run 免 FUSE)
# ---------------------------------------------------------------------------
build_appimage() {
  local edition="$1" label="$2"    # edition: vga|ega   label: QFG1-CHT-VGA / QFG1-CHT-EGA
  local appdir="$STAGE/AppDir-$edition"
  log "=== AppImage $label ==="
  rm -rf "$appdir"
  mkdir -p "$appdir/usr/bin" "$appdir/usr/lib"

  cp "$ROOT/scummvm-src/scummvm" "$appdir/usr/bin/scummvm"
  docker run --rm -v "$appdir/usr/bin:/b" qfg1-capture strip /b/scummvm 2>/dev/null || true

  log "收集共享庫依賴(在 qfg1-capture runtime 內 ldd,排除 glibc 核心)"
  docker run --rm \
    -v "$appdir/usr/bin/scummvm:/collect/bin:ro" \
    -v "$appdir/usr/lib:/collect/out" \
    -v "$ROOT/tools/pkg_collect_libs.py:/collect/collect.py:ro" \
    -w /collect qfg1-capture python3 collect.py bin out
  log "   共 $(ls "$appdir/usr/lib" | wc -l) 個 .so"

  cat > "$appdir/AppRun" <<'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/usr/bin/scummvm" "$@"
APPRUN
  chmod +x "$appdir/AppRun"

  cat > "$appdir/qfg1-cht.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=${label}
Comment=Quest for Glory I / Hero's Quest 繁體中文化(ScummVM patch)
Exec=scummvm
Icon=qfg1-cht
Categories=Game;
Terminal=false
DESK
  cp "$ROOT/tools/assets/icon.png" "$appdir/qfg1-cht.png"
  ln -sf qfg1-cht.png "$appdir/.DirIcon"

  # 中文資料包 + README 一併放進 AppDir(usr/share),整份 AppImage = 完整可交付單元
  stage_cht_data "$edition" "$appdir/usr/share/cht-data-${edition}"
  gen_readme "$edition" linux > "$appdir/usr/share/README.txt"

  local out="$DIST/${label}-x86_64.AppImage"
  rm -f "$out"
  # appimagetool 需要 `file` 指令判斷 ELF 架構;qfg1-build 沒裝,現場裝(apt cache 隨容器 --rm 即棄)
  docker run --rm -v "$STAGE:/stage" -v "$ROOT/tools/.cache:/tools:ro" -e ARCH=x86_64 -w /stage \
    qfg1-build bash -c "apt-get update -qq >/dev/null && apt-get install -y -qq file >/dev/null && \
      /tools/appimagetool-x86_64.AppImage --appimage-extract-and-run 'AppDir-$edition' '/stage/$(basename "$out")'"
  mv "$STAGE/$(basename "$out")" "$out" 2>/dev/null || true
  chmod +x "$out" 2>/dev/null || true   # docker(root) 產出的檔通常已是 755,chmod 失敗可忽略
  log "   -> $out ($(du -h "$out" | cut -f1))"
}

# ---------------------------------------------------------------------------
# 2) Windows zip:scummvm.exe + DLL + 中文資料 + README.txt + .bat 啟動器
# ---------------------------------------------------------------------------
build_windows_zip() {
  local edition="$1" label="$2"
  local stage="$STAGE/${label}-windows"
  log "=== Windows zip $label ==="
  rm -rf "$stage"; mkdir -p "$stage"

  local exe="$ROOT/build/win64/src/scummvm.exe"
  [ -f "$exe" ] || die "找不到 Windows 引擎 $exe(先跑 mingw docker build)"
  cp "$exe" "$stage/scummvm.exe"
  docker run --rm -v "$stage:/s" qfg1-mingw x86_64-w64-mingw32-strip /s/scummvm.exe 2>/dev/null || true

  docker run --rm qfg1-mingw cat /usr/x86_64-w64-mingw32/bin/SDL2.dll > "$stage/SDL2.dll"
  docker run --rm qfg1-mingw cat /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll > "$stage/libwinpthread-1.dll"

  local dataname="cht-data-${edition}"
  stage_cht_data "$edition" "$stage/$dataname"

  local edition_upper
  edition_upper="$(echo "$edition" | tr '[:lower:]' '[:upper:]')"
  cat > "$stage/玩英雄傳奇I-繁中.bat" <<BAT
@echo off
setlocal enabledelayedexpansion
echo 英雄傳奇 I 繁體中文化 — ${edition_upper}
echo.
set /p GAMEDIR=請輸入你的英雄傳奇I(${edition_upper})遊戲資料夾路徑,按 Enter 確認:
if not exist "%GAMEDIR%" (
  echo 找不到路徑,請確認後重新執行本啟動器。
  pause
  exit /b 1
)
xcopy /y /q "%~dp0${dataname}\*" "%GAMEDIR%\" >nul
echo 已將中文資料複製進遊戲資料夾,啟動 ScummVM...
"%~dp0scummvm.exe" --language=tw --path="%GAMEDIR%" --auto-detect
pause
BAT
  unix2dos "$stage/玩英雄傳奇I-繁中.bat" 2>/dev/null || sed -i 's/$/\r/' "$stage/玩英雄傳奇I-繁中.bat"

  gen_readme "$edition" windows > "$stage/README.txt"
  sed -i 's/$/\r/' "$stage/README.txt"

  local out="$DIST/${label}-windows-x86_64.zip"
  rm -f "$out"
  ( cd "$STAGE" && zip -qr "$out" "$(basename "$stage")" )
  log "   -> $out ($(du -h "$out" | cut -f1))"
}

# ---------------------------------------------------------------------------
# 3) dev-setup tar.gz:patches/ + apply_patches.sh + docker/ + BUILD.md
# ---------------------------------------------------------------------------
build_dev_setup() {
  local stage="$STAGE/qfg1-cht-dev-setup"
  log "=== dev-setup ==="
  rm -rf "$stage"; mkdir -p "$stage"
  cp -r "$ROOT/patches" "$stage/"
  mkdir -p "$stage/tools"
  cp "$ROOT/tools/apply_patches.sh" "$stage/tools/"
  cp -r "$ROOT/docker" "$stage/"
  cp "$ROOT/BUILD.md" "$stage/" 2>/dev/null || log "   (BUILD.md 待生成,見 tools/package.sh 呼叫順序)"

  local out="$DIST/qfg1-cht-dev-setup-${DATE_TAG}.tar.gz"
  rm -f "$out"
  ( cd "$STAGE" && tar czf "$out" "$(basename "$stage")" )
  log "   -> $out ($(du -h "$out" | cut -f1))"
}

# ---------------------------------------------------------------------------
main() {
  local target="${1:-all}"
  case "$target" in
    all)
      rebuild_cht_data
      build_appimage vga QFG1-CHT-VGA
      build_appimage ega QFG1-CHT-EGA
      build_windows_zip vga QFG1-CHT-VGA
      build_windows_zip ega QFG1-CHT-EGA
      build_dev_setup
      ;;
    appimage)
      rebuild_cht_data
      build_appimage vga QFG1-CHT-VGA
      build_appimage ega QFG1-CHT-EGA
      ;;
    windows)
      rebuild_cht_data
      build_windows_zip vga QFG1-CHT-VGA
      build_windows_zip ega QFG1-CHT-EGA
      ;;
    dev-setup)
      build_dev_setup
      ;;
    *)
      die "未知目標:$target(可用:all appimage windows dev-setup)"
      ;;
  esac
  echo
  log "=== dist/packages/ 產出 ==="
  ls -la "$DIST"
}

main "$@"
