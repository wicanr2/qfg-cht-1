#!/usr/bin/env bash
# 共用函式:中文資料 staging + 玩家 README 生成。
# 供 tools/package.sh(本機 Linux/Windows/dev-setup)與 tools/package_macos_data.sh(macOS CI 後製)共用,
# 確保三平台的中文資料內容與說明文字一致、不因各自維護一份而drift。
#
# 用法:source tools/pkg_common.sh   (呼叫端須先定義 ROOT 變數,指向 repo 根目錄)

# 中文資料包 staging:$1=vga|ega  $2=輸出目錄
stage_cht_data() {
  local edition="$1" out="$2"
  rm -rf "$out"; mkdir -p "$out"
  if [ "$edition" = vga ]; then
    cp "$ROOT/dist/translation.tsv" "$ROOT/dist/qfg1_big5.fnt" "$out/"
    # glob 當下所有 view/pic patch,別寫死清單(父代理仍在陸續增加 baked-art)
    cp "$ROOT"/art/vga/*.p56 "$ROOT"/art/vga/*.v56 "$out/" 2>/dev/null || true
  else
    cp "$ROOT/dist_ega/translation.tsv" "$ROOT/dist_ega/qfg1_big5.fnt" "$out/"
  fi
  echo ">>    staged $(ls "$out" | wc -l) 個中文資料檔 → $out"
}

# 中文資料包玩家 README(繁中,說明部署方式):$1=vga|ega  $2=linux|windows|macos
gen_readme() {
  local edition="$1" platform="$2"
  local edition_zh archive_hint
  if [ "$edition" = vga ]; then
    edition_zh="VGA(1992 重製版 *Quest for Glory I*,256 色)"
    archive_hint="QFG1.zip 解壓後的資料夾"
  else
    edition_zh="EGA(1989 原版 *Hero's Quest*,16 色)"
    archive_hint="000795_heros_quest.7z 解壓後的資料夾"
  fi
  cat <<EOF
英雄傳奇 I 繁體中文化 — $edition_zh

本包內容
--------
- patched ScummVM 執行檔(含 Big5 繪字 + ZH_TWN 語言支援的引擎改動)
- cht-data-${edition}/:中文資料(translation.tsv 對白/訊息、qfg1_big5.fnt 字型$([ "$edition" = vga ] && echo '、view/pic 美術字 patch'))
- 本說明檔

本包【不含】原遊戲資源。請自備合法取得的英雄傳奇 I ${edition} 版遊戲檔。

安裝步驟
--------
1. 準備好你自己的 $archive_hint(內含 RESOURCE.* 等遊戲資料,檔名請一律小寫)。
2. 把 cht-data-${edition}/ 資料夾內的所有檔案,複製進上述遊戲資料夾(與 RESOURCE.* 同一層)。
3. 執行本包的 ScummVM 執行檔(見下方「執行方式」)。
4. 在 ScummVM 啟動器按「Add Game...」,選剛才那個遊戲資料夾加入。
5. 加入後在 Game Options 把 Language 設為 Chinese(Taiwan)(或啟動時帶 --language=tw),即可看到繁體中文。

執行方式
--------
EOF
  case "$platform" in
    linux)
      cat <<'EOF'
./QFG1-CHT-*-x86_64.AppImage
（AppImage 本身已內含執行必需的共享庫,免安裝系統套件；若你的系統禁用 FUSE 執行 AppImage,
 可改用 --appimage-extract-and-run 或直接執行同目錄展開的 AppRun。）
EOF
      ;;
    windows)
      cat <<'EOF'
雙擊「玩英雄傳奇I-繁中.bat」,依提示輸入你的遊戲資料夾路徑即可
（.bat 會把 cht-data 複製進該資料夾,並以 --language=tw 啟動 scummvm.exe）。
也可手動執行:scummvm.exe --language=tw --path="你的遊戲資料夾路徑" --auto-detect
EOF
      ;;
    macos)
      cat <<'EOF'
把 ScummVM.app 拖進「應用程式」,第一次執行前先解除 Gatekeeper 隔離(未簽署 app):
  xattr -dr com.apple.quarantine /Applications/ScummVM.app
中文資料已預先放進 .app/Contents/Resources/cht-data-<edition>/,
仍需依「安裝步驟」複製到你自己的遊戲資料夾(.app 本身不含遊戲資源)。
啟動:開啟 ScummVM.app 後在啟動器 Add Game,或終端機:
  ScummVM.app/Contents/MacOS/scummvm --language=tw --path="你的遊戲資料夾路徑" --auto-detect
EOF
      ;;
  esac
  cat <<'EOF'

交付原則
--------
中文化僅以 ScummVM patch 形式交付(引擎改動 + 中文資料),原遊戲資源不入包、不散布。
repo:https://github.com/wicanr2/qfg-cht-1
EOF
}
