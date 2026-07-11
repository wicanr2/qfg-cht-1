# 英雄傳奇 I 繁中化 — 工作交接 / worklist(截至 2026-07-11)

repo:`github.com/wicanr2/qfg-cht-1`(main,已 push)。工作目錄 `~/scummvm/qfg-1/workplace`。

## 現況快照

| 里程碑 | 狀態 |
|---|---|
| M0 可行性 | ✅ 可行(`docs/00-feasibility.md`) |
| M1 端到端打通 | ✅ 引擎 `ZH_TWN`+Big5 + TSV 內容替換,實機驗證 |
| **M2 VGA 全文字中文化** | ✅ **4480/4521 則(99%)** 對白/敘述/訊息 |
| M2 古風字型 | ✅ AR PL UMing TW 明體 15px,烘 2486 字 Big5 |
| **路線A view/pic 編碼器** | ✅ `tools/sci_view.py`(view + **pic**),view 908 / pic 904 spike 皆實機驗證(cel→「英雄」、Strength→「力量」) |
| **M3 EGA 文字中文化** | ✅ **3878/3883(99%)**,1561 沿用 VGA + 2317 haiku;實機驗證版權文 |
| **M2-D VGA baked-art 重繪** | ✅ 角色創建:pic 904(13 屬性/技能名 + 姓名/經驗/生命/體力/法力)+ view 802(開始/取消/可分配點數)。**mnemonic overlay 對撞已修**:清空 view 802 loop1/2 的 26 個英文首字母 cel(蓋在中文標籤上成「S量」),露出 pic 中文,實機驗證(見 2026-07-11 輪) |
| **M4 多平台打包 + Release** | ✅ macOS CI 已實跑;**GitHub Release `v1.0` 已發**,6 平台包(AppImage/Windows/macOS × VGA/EGA)+ dev-setup,**僅 patch 無遊戲資源**。含遊戲完整包在 `dist-all/`(私人保留,gitignore) |
| 密碼/通關語 | ✅ 打字硬關就地附英文答案(盜賊 `schwertfisch`、女巫 `Hut of Brown, Now Sit Down`),VGA+EGA;`docs/70-passwords-and-riddles.md`(全關卡問題中/英+答案) |
| 可玩性測試 | ✅ VGA/EGA 兩版實機驗證可玩;**in-game 對話已走到村莊 NPC**(VGA「歡迎來到我們的城鎮」、食人妖描述框)實機驗證 hi-res 中文銳利、行首字完整 |
| **hi-res live 中文字(#3)** | ✅ `ZH_TWN` 啟 640×400 + 32×28 hi-res Big5 字模直繪(VGA+EGA 對白/credits 銳利);對白斷行行首字掉左偏旁一併修好 |
| 推廣影片 | ✅ `out/video/qfg1_cht_promo.mp4`(44s,VGA/EGA 穿插 + 原版配樂;版權素材 gitignore) |

## VGA baked-art 已識別(角色創建畫面)
- **pic 904**(320×200 背景圖):烘了 13 個屬性/技能名(Strength/Intelligence/…/Climbing)+ Name:/Experience/Health/Stamina/Magic Points。**pic 解碼/編碼器已完成並實機驗證**(`sci_view.py pic-decode/pic-verify/pic-roundtrip/pic-encode`,細節見 `docs/40-baked-art-ui.md`);下一步是把 13 個標籤逐一重繪成中文明體(目前只 spike 驗證了 Strength→「力量」一個標籤,其餘 12 個 + Name:/Experience/Health/Stamina/Magic Points 待做)。
- **view 802**:start(loop3/cel0 82×13 @9,157)、cancel(loop4/cel0 82×14 @9,170)、Points Available(loop7/cel0 110×14 @102,140)+ 屬性小雕像 + mnemonic 疊字。→ 用 `sci_view.py encode --replace`。
- **EGA 版角色創建屬性名 = 純文字(text.204)**,已隨 M3 文字化,不必改圖。

## EGA 待補
- 只抽了 `text.*`(3883 則)。EGA 部分對白/字串可能在 `script.*` 內嵌(grep 命中),需檢查覆蓋、補抽。
- 實機驗證更多 EGA 畫面(對白/選單);\n 硬換行畫面觀感。

## 交付原則(硬)
- 中文化**僅放 ScummVM patch**:引擎改動(`patches/`)+ `dist/`(translation.tsv + qfg1_big5.fnt)+ view/pic patch。原遊戲資源不入庫。
- 完整性:EGA/VGA 兩版都要交付。
- **Release 只放不含遊戲的 patch 版;含遊戲完整可玩包只在本機 `dist-all/`(gitignore),私人保留。**

## 2026-07-11 輪(密碼附答案 + 可玩性測試 + baked-art 收尾 + Release)

1. **打字硬關就地附英文答案**:玩家必須打對英文才過的關,譯文問句後補 `(輸入:...)`,答案維持 ASCII(過 Big5 不變、parser 仍比對得到)。
   - 盜賊口令 `schwertfisch`(酒館克拉舍);女巫小屋咒語 `Hut of Brown, Now Sit Down`(VGA `What is the rhyme?` / EGA `go ahead and say the rhyme`)。VGA+EGA `translation.tsv` 都改。
   - **玩笑關別附正解**:Erasmus「三道謎題」答對答錯都被傳送進去(致敬《聖杯》),不是硬門檻。
   - 全整理進 `docs/70-passwords-and-riddles.md`(問題中/英+答案表),README 技術文件索引補一列。
2. **可玩性測試**(派 subagent):VGA/EGA 兩版開機/中文渲染/baked-art/進角色創建皆 PASS,無阻斷。in-game 對話因 headless 合成鍵無法穩定完成「命名對話框→進場」未走完,以離線佐證,建議真機補測。
3. **VGA baked-art mnemonic overlay 收尾**:角色創建 runtime 時 view 802 loop1/2 的英文首字母縮寫(S/I/A/V/L/M…,兩色狀態)疊在 pic 904 中文標籤上成「S量」。清空 26 個 cel(同尺寸 `alpha=0` PNG,`sci_view.py encode --replace`),露出中文,實機驗證。**「magic user」殘留查為 2026-07-09 舊截圖誤報**,現行 506.v56 職業名牌已是 戰士/法師/盜賊。
4. **Release `v1.0` 發布 + 對齊**:6 平台包全部帶最新譯文 + baked-art;macOS 靠 CI(`build-macos.yml` dispatch → `gh run download` → `gh release upload --clobber`)。`dist-all/` 六完整包重建。
   - **經驗沉澱**:SCI CHT 方法論(kb `scummvm-sci-cht-localization` + my_skill)補「baked-art overlay 對撞→清空 cel」「打字硬關附答案」;「CI 監控派便宜 agent、旗艦別背景 poll」寫入 `rulebook/35`+`45` + kb `mac-app-cross-pack`。

## 2026-07-11 輪(EGA 深化:序章標題 + kFormat 動態句 + credits + 全平台重發)

> 使用者實機玩 EGA full AppImage 陸續回報序章英文殘留;派 audit subagent 全程盤點後批次修。

1. **dist-all 交付形式改寫**(`tools/build_distall.sh`):產 **full self-contained AppImage**(遊戲內嵌 + AppRun 帶 `--path/--language`,`./AppImage` 直接玩免腳本)+ Windows/macOS 完整包 **zip**(macOS 用 `zip -y` 保留 .app symlink)。含遊戲資源→僅本機 `dist-all/`。
2. **EGA 序章標題 `HERO'S QUEST` → 英雄傳奇**(`view.909`,SCI0 EGA view,可編非向量)。照原版風格(哥德花體→Noto Serif Bold、洋紅描邊 + 紅熔岩填充 + 黃/白火花,嚴格限 EGA 16 色)重繪全 26 幀:loop0/2 灰色頂部揭露飛入、loop1/3 洋紅熔岩閃爍定位。in-engine 驗證(灰飛入→頂部定色,版面同原版)。
3. **kFormat 動態句 hook**(引擎,`kstring.cpp`→`patches/0001`):`kFormat` 代換 `%s`/`%d` 前把「模板」查表換中文模板(`GfxText16` 內容比對只看代換後字串,抓不到動態句)。支援**子序列對應 + 參數重映射**(中文可少於英文規格、丟英文複數 `%s`);**防呆**:含 `%s` 的非精確對應退回英文(`%s` 走 `argv` 直取不經重映射,錯位會崩)。單元測試 6 情形正確。修好「Good luck in your quest, <名>」等 ~20 動態句(VGA+EGA 共用引擎);gold/silver 複數句也修(視覺待真機確認,headless 開不了物品欄)。
4. **credits 職稱標題詞**(`view.902`,15 cel):14 洋紅職稱(編劇/導演/程式設計/動畫/背景/場景/遊戲/開發/系統/製作/執行/監製)+ 音樂 譯中文;**人名保留原文**;「與」11px 太糊留空。in-engine 驗證。
5. **MAGIC USER → 法師**(`view.506` loop2,死資源,綠+洋紅)。
6. **全平台重發**(引擎改動影響 VGA+EGA):重編 Windows(mingw)+ Linux 引擎、`package.sh all`、macOS CI 重編、`gh release upload --clobber` 6 平台包 + dev-setup(刪舊 20260710)、重建 dist-all。打包/上傳/CI 監控派便宜 subagent 執行。

**EGA 待辦(未在本批)**:序章副標「So You Want To Be A Hero」仍英文(view,可另做);kFormat gold/silver 中文輸出待真機視覺確認;職業選擇 11px 中文字偏小(EGA 320×200 先天限制,要更銳需 SCI0 hi-res 字型路徑=較大引擎工程)。

## 2026-07-11 深夜輪(#3 hi-res live 中文字 + 對白斷行修正 + 全平台重發)

> 使用者授權「開分支執行 #3、接受風險、完成經典」。#3 在 `feature/ega-hires-cht-font` 完成並實機驗證後合併回 main。

1. **#3 hi-res live 中文字路徑**(引擎):`screen.cpp` 在 `ZH_TWN && UPSCALED_DISABLED` 時強制 `GFX_SCREEN_UPSCALED_640x400`;`GfxFontChinese` 另載 **32×28 hi-res Big5 字模**(`tools/bake_hires_font.py` 烘,`qfg1_big5_hi.fnt`,VGA+EGA 共用),雙位元組字在 640×400 下 `drawHiRes()` 直寫 display buffer(暫開 `_fontIsUpscaled`、座標 ×2),ASCII 仍走原字型 2× upscale。實機:VGA/EGA 對白、credits「遊戲設計」皆銳利、無崩潰。
2. **對白框行首字掉左偏旁修正**(`text16.cpp GetLongest`):PC-98 日文 SJIS kinsoku 分支(多塞一個超 maxWidth 的雙位元組字)因 `isDoubleByte` 對 Big5 也成立而被繁中誤觸,長行 `textWidth>rect.width()`→`Box()` CENTER offset 變負→行首字左偏旁被裁(你→尔、據→豦、這掉辶)。ZH_TWN 改斷在容得下的最後一字,日文路徑 `lang!=ZH_TWN` gate 不動。**實機驗證**:村莊食人妖描述框滿寬置中行「這個奇怪且笨重的角色」行首「這」辶偏旁完整。低解析亦有此病,一併修好。
3. **playtest 誤報澄清**:VGA 頂部狀態列 `152× font.0 glyph drawn out of bounds` 經查是 **QFG1 VGA 英文上游本來就有的水平溢出**(英文 run 同樣 152 次、X=324–358),非 hi-res 迴歸、非在地化造成,不處理。
4. **全平台重發**:重編 Linux + Windows(mingw)引擎、`package.sh all`、macOS CI(`gh workflow run build-macos.yml`)重編、更新 Release v1.0(6 平台包 + dev-setup)、重建 dist-all。CI 監控派 haiku subagent。
5. patch 重生:`text16.cpp` hunk 以 pristine(upstream 3d408ec)`diff -u` 重生抽換進 `0001`,全 11 檔對 pristine `patch -p0 --dry-run` 驗證可套。

## M4 打包(2026-07-10)

`tools/package.sh` 一鍵組裝,輸出到 `dist/packages/`(本機驗證過的 5 個檔):
- `QFG1-CHT-VGA-x86_64.AppImage` / `QFG1-CHT-EGA-x86_64.AppImage`:手工 AppDir(非 linuxdeploy)+
  `tools/pkg_collect_libs.py` 遞迴 `ldd` 收集 56 個共享庫(排除 glibc 核心)+ `appimagetool
  --appimage-extract-and-run`(免 FUSE)。已用 Xvfb 實機跑過,builtin 主題 fallback 正常顯示。
- `QFG1-CHT-VGA-windows-x86_64.zip` / `QFG1-CHT-EGA-windows-x86_64.zip`:`scummvm.exe` +
  `SDL2.dll` + `libwinpthread-1.dll` + 中文資料 + `.bat` 啟動器(互動輸入遊戲路徑,自動 xcopy 中文資料
  + `--language=tw` 啟動)。
- `qfg1-cht-dev-setup-YYYYMMDD.tar.gz`:`patches/`(含新增的 `UPSTREAM_COMMIT.txt` pinned commit,
  已用 GitHub 內容比對驗證)+ `tools/apply_patches.sh`(現支援 `$SRC` 不存在時自動 clone+checkout)+
  `docker/` + `BUILD.md`。

macOS(`.github/workflows/build-macos.yml` + `tools/package_macos_data.sh`)未在本機跑(不能在
Linux 交叉編譯 macOS),邏輯已用假 `.app` 本機驗證中文資料注入 + tar 重打包正常;workflow 本身
未經 CI 實跑驗證,首次執行可能需微調(見 BUILD.md §3 與 workflow 內註解)。

**發現**:ScummVM 對 SCI 引擎有 builtin GUI 主題 fallback(缺 `scummclassic.zip` 等 GUI data 檔會印
warning 但正常運作,不影響遊戲本身),故三平台打包都不需要附帶 ScummVM 自己的 GUI theme/engine-data
檔(先前 sibling 專案 qog-2 因 AGS 需要而全附,本專案 SCI-only 裁剪版不需要)。

## 下一步(接續就做):M2-D1 角色創建畫面 baked-art 中文化

1. **識別**角色創建畫面的標籤 view/cel(屬性名 Strength/Intelligence/Agility/Vitality/Luck/Magic、
   技能 Weapon Use/Parry/Dodge/…、Name:/start/cancel)。
   - 這些是**烘進 view 的美術字**(非文字資源,`docs/40-baked-art-ui.md` 已查證)。
   - 方法:到角色創建畫面跑 `SCI_LOG_GFX`(log `view=N loop=L cel=C WxH @(x,y)`),依座標/尺寸對出標籤 cel;
     或在 `out/allviews/`(6678 個 dump PPM)裡比對。判斷是「單一大 cel 含全部標籤」或「逐標籤 cel」。
   - 導航到角色創建(headless 不穩,多試):`~17×ESC` 跳 intro/credits 到職業選擇 → 點雕像(~300,220)→ Enter。
     參考 `tools/capture_charcreate.sh`。到達的畫面見 `docs/images/m2-charcreate-baked-art.png`。
2. **重繪**每個標籤成中文(明體、貼原羊皮紙美術風),用原 view 的 embedded palette 既有色(避免 RGB→index 失真)。
3. **編碼** patch:`tools/sci_view.py encode <view> <out> --replace loop,cel,zh.png --patch` → `<id>.v56`。
4. **驗證**:patch 放遊戲目錄 → 實機到角色創建看中文;或 `SCI_DUMP_RES` 重 dump 比對。
5. 重繪為機械美術活,可**分派 subagent**(參 `docs/45` 成本分工;識別/把關旗艦做)。

## 關鍵工具 / 指令

### 引擎 build(docker,SCI-only)
```
docker run --rm -v "$PWD/scummvm-src:/src" -w /src qfg1-build bash -c \
  "./configure --disable-all-engines --enable-engine=sci --disable-detection-full --disable-mt32emu && make -j$(nproc)"
```
- image `qfg1-build`(debian12+libsdl2-dev)、`qfg1-capture`(+xvfb/imagemagick/xdotool),Dockerfile 在 `docker/`。
- **configure 順序**:`--disable-all-engines` 必須在 `--enable-engine=sci` **之前**(反了 sci 被關)。

### 翻譯 pipeline(文字)
```
# 抽字(一次性):timeout 40 docker run -e SCI_DUMP_RES=/out/dump ... 然後
docker run ... uv run tools/extract_strings.py out/dump translation/skeleton.tsv
# 併譯 + 建 runtime:
docker run ... uv run tools/merge_translations.py translation/skeleton.tsv translation/translation.tsv translation/batch/*.tsv
docker run ... uv run tools/build_cht.py translation/translation.tsv dist   # 明體 + Big5 + 標點正規化
```

### view 編解碼(baked-art)
```
docker run ... uv run tools/sci_view.py decode|verify|roundtrip|encode ...
```

### 實機截圖(headless)
Xvfb + `import -window root`;`--language=tw` 啟用中文(**不是 zh_TW**)。遊戲目錄用**小寫檔名**(`extract/vga_lc`)。

## 踩雷(別重踩)
- 引擎 dump hook(`SCI_DUMP_RES`/`SCI_DUMP_ALLVIEWS`)跑完**不會自退**,docker run **一律 `timeout` 包住**,否則 headless 空跑卡住(本 session 卡過兩個容器)。
- 別 kill 別專案的 docker 容器(vms3/imec/core_traffic/comic2…);只清 `qfg1-build`/`qfg1-capture`。
- 半形標點會走 ASCII 小字型 → `build_cht.py` 已 fullwidthize;新譯文仍應用全形。省略號 `…` 非 `⋯`。
- credits 花體字、標題「Wanted Hero」(pic 100)也是 baked 美術字(view/pic),同路線 A 處理。

## 引擎改動(`patches/0001-sci-cht-zh_twn.patch` + `patches/fontchinese.{h,cpp}`)
- `GfxFontChinese`(Big5 繪字)、`cache.cpp`/`text16.cpp` ZH_TWN hook、`sci.cpp` getLanguage 覆蓋 + `loadChtTranslation` + 各 dump hook。
- 套用:`tools/apply_patches.sh <scummvm-src>`。

## 記憶
`~/.claude/projects/-home-anr2-scummvm-qfg-1/memory/qfg1-cht-architecture.md`(架構 + build 踩雷)。
