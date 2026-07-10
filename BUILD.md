# 英雄傳奇 I 繁中化 — 開發者 Build 手冊

本檔案是 dev-setup 交付包的核心文件:拿到 `patches/` + `docker/` + `tools/apply_patches.sh` 後,
照本檔步驟即可在 Linux / Windows(交叉編譯)/ macOS(CI)三個平台重建 patched ScummVM 引擎。

引擎架構背景見 `docs/20-engine-cjk-patch.md`;中文資料 build 見 `docs/30-text-pipeline.md`。

## 0. 前置準備

1. 取得乾淨的 ScummVM 原始碼(建議與本專案開發時同一版本;`patches/0001-sci-cht-zh_twn.patch` 是對該版本樹的 diff,版本差太多可能 patch 失敗需手動調整)。
2. 套用中文化引擎改動:
   ```bash
   tools/apply_patches.sh <scummvm-src-dir>
   ```
   這會:複製新檔 `engines/sci/graphics/fontchinese.{h,cpp}`(`GfxFontChinese`:Big5 繪字)、
   對既有檔案套用 `patches/0001-sci-cht-zh_twn.patch`(`cache.cpp`/`text16.cpp` 的 ZH_TWN hook、
   `sci.cpp` 的 `getLanguage()` 覆蓋 + `loadChtTranslation` + dump hook)。

## 1. Linux(x86_64,native)

```bash
docker build -t qfg1-build -f docker/Dockerfile.build .
docker run --rm -v "$PWD/<scummvm-src>:/src" -w /src qfg1-build bash -c \
  "./configure --disable-all-engines --enable-engine=sci --disable-detection-full --disable-mt32emu && make -j$(nproc)"
```

**[HARD] configure 順序**:`--disable-all-engines` 必須在 `--enable-engine=sci` **之前**。反了 sci 引擎會被關掉
(`config.h` 內 `# ENABLE_SCI` 被註解掉,`--list-engines` 看不到 sci)。

**必加的兩個 flag**:
- `--disable-detection-full`:否則會編譯全部引擎的 detection.o,`testbed` 因缺 config.h 而中斷 build。
- `--disable-mt32emu`:複製樹內建的 MT-32 版本巨集在本專案的裁剪配置下會失效,導致連結錯誤。

產出:`<scummvm-src>/scummvm`(ELF x86-64,動態連結一堆系統庫,不可直接發布——打包時用
`tools/pkg_collect_libs.py` 收集依賴,或走 `tools/package.sh appimage`)。

## 2. Windows(x86_64,mingw-w64 交叉編譯)

```bash
docker build -t qfg1-mingw -f docker/Dockerfile.mingw .
docker run --rm -v "$PWD/<scummvm-src>:/src" -w /src qfg1-mingw bash -c \
  "./configure --host=x86_64-w64-mingw32 --disable-all-engines --enable-engine=sci \
     --disable-detection-full --disable-mt32emu && make -j$(nproc)"
```

`Dockerfile.mingw` 已內建:mingw-w64 toolchain(posix threading variant,ScummVM 需要 `std::thread`)、
SDL2 mingw 官方預編譯 devel 包、原始碼交叉編譯的 static zlib。

產出:`<scummvm-src>/scummvm.exe`(PE32+)。**隨附 DLL**(玩家端沒裝 mingw runtime,缺了會直接無法啟動):
```bash
docker run --rm qfg1-mingw cat /usr/x86_64-w64-mingw32/bin/SDL2.dll > SDL2.dll
docker run --rm qfg1-mingw cat /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll > libwinpthread-1.dll
```
可選 `x86_64-w64-mingw32-strip scummvm.exe` 縮小體積。

## 3. macOS(x86_64 + arm64 universal,GitHub Actions CI)

**不能在 Linux 交叉編譯 macOS**(Apple SDK EULA + codesign/hdiutil 只在 macOS host)。
用 `.github/workflows/build-macos.yml`(`macos-14` runner,Apple Silicon)。細節與踩雷收在
skill `re-retro-cht-rulebook` → kb `mac-app-cross-pack`,這裡摘要對本專案有效的部分:

- **[HARD] ScummVM 的 `configure` 不是 autoconf**——`CXXFLAGS`/`LDFLAGS` 只能當環境變數餵,
  不能當 `KEY=VALUE` 位置參數(它是手寫 shell script,`SAVED_CXXFLAGS=$CXXFLAGS` 從環境讀)。
  `CXXFLAGS="-arch $ARCH -mmacosx-version-min=$MIN" ./configure ...` 才對;
  `CXXFLAGS=... ./configure` 當引數傳會報 `error: unrecognized option: CXXFLAGS=-arch`。
- **universal binary 用「每弧各編一次 + `lipo -create`」**,不要對 autoconf 專案單次雙弧塞
  `-arch arm64 -arch x86_64`(configure 版本解析在雙 `-arch` 下會炸:`integer expression expected`)。
  x86_64 弧在 Apple Silicon runner 上用 `arch -x86_64` 走 Rosetta 編。
- **[HARD] 不要用 brew 的 `sdl2`**:2026 起 Homebrew 的 `sdl2` 已換成 `sdl2-compat`
  (~0.5MB shim,runtime 才 `dlopen libSDL3`),dylibbundler 抓不到這個 runtime 依賴,
  玩家端會「Failed loading SDL3 library」黑畫面。改自源碼編 pinned 真 SDL2(2.30.9),
  `otool -L libSDL2*.dylib | grep -qi SDL3` 抓不到才是真的。
- **dylibbundler 對自編(非 brew)SDL 會互動式無限 hang**(`@rpath` install name 解不到、
  CI 無 stdin 卡到 timeout)。修法:`dylibbundler ... -s "$SDL_PREFIX/lib" </dev/null`
  (給搜尋路徑 + `/dev/null` 防呆讓它 fail-fast 而非 hang)。
- **per-arch+lipo 路線下 dylibbundler 只會挑到單一弧的 SDL2 dylib**(universal 主程式配非-fat
  相依庫)。SCI engine 只需要 SDL2(不需 libmad/libvorbis 等 AGS 才要的東西時),簡化為手動
  `lipo -create` 兩弧 SDL2.dylib + `install_name_tool -change` 改主程式兩個弧各自的舊路徑,
  取代 dylibbundler。驗證要對「主程式」與「Frameworks 內 SDL2」都斷言雙弧
  (`lipo -info` 看到 `arm64` 且 `x86_64`),只查「存在」查不到單弧退化。
- **Xcode 15 Clang 預設 C++20** 把 `std::unary_function`/`std::binary_function`(C++17 後移除)
  弄壞——ScummVM 本身較新應無此問題,但若改動較舊的 patch 檔要注意。
- **`macos-13`(Intel)已退役**,需要 Intel job 改 `macos-15-intel`;本專案走
  單一 `macos-14` + universal,對 runner 退役免疫。
- **雙保底**:`.dmg`(APFS,`hdiutil create -format UDZO`,方便雙擊)+ `.tar.gz`
  (保留 Unix perm,繞開「APFS DMG 在非 Mac 平台讀不到」問題)同時 ship。

CI 產出的 `.app`/`.tar.gz` 是「空引擎」,不含中文資料——用
`tools/package_macos_data.sh <app-or-tar-path> vga|ega <輸出目錄>` 把 `dist/`(或 `dist_ega/`)+
`art/vga/*.p56 *.v56` 塞進 `.app/Contents/Resources/cht-data-<edition>/` 並重新打包成交付檔。

## 4. 打包(本機可做的 4 個交付檔)

```bash
tools/package.sh          # AppImage x2 + Windows zip x2 + dev-setup tar.gz,輸出到 dist/packages/
tools/package.sh appimage # 只做 Linux AppImage
tools/package.sh windows  # 只做 Windows zip(需先跑過上面 §2 產出 build/win64/src/scummvm.exe)
```

AppImage 用手工 AppDir + `appimagetool`(`--appimage-extract-and-run`,免 FUSE)組裝,依賴收集用
`tools/pkg_collect_libs.py`(遞迴 `ldd`,排除 glibc 核心 `libc/libm/libpthread/ld-linux` 等——
這些假設任何目標 Linux 都有,打包反而可能鎖死相容性)。

## 5. 交付原則(硬,不可違反)

中文化**僅以 ScummVM patch 形式交付**:patched 引擎 + 中文資料(`translation.tsv` + `qfg1_big5.fnt` +
VGA 的 view/pic patch)+ README。**原遊戲資源(`RESOURCE.*` 等)絕不入包**,使用者自備合法遊戲檔。
