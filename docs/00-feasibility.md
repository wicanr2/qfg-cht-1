# 英雄傳奇1 (Quest for Glory I) ScummVM 繁中化 — 可行性評估

> 日期:2026-07-09。狀態:研究可行性(未動工)。
> 交付定位:規劃文件,repo 的唯一真相;後續里程碑對此修訂。

## 結論(先行)

**可行,且路線明確**。核心不是「從零改引擎」,而是**沿用 ScummVM SCI 引擎既有的韓文/日文 CJK 範式,新增一條繁體中文(`ZH_TWN` + Big5)路徑**。韓文 SCI fan translation 做的事跟本專案幾乎一模一樣,是現成範本。

與隔壁 `qog-2`(英雄傳奇2)**不能照抄**:qog-2 用的是 AGDI 的 VGA fan-remake,引擎是 **AGS**;本專案 QFG1 是 Sierra 原版 **SCI 引擎**。可借鏡的是「字型烘製 pipeline、翻譯術語紀律、多平台打包、ScummVM patch 交付」,不可借鏡的是「引擎層繪字 hook」。

---

## 1. 版本確認(已核實,來自壓縮檔內容)

| 版本 | 素材 | 引擎 | 文字資源 | 備註 |
|---|---|---|---|---|
| **EGA** | `000795_heros_quest.7z`(4× 737KB 軟碟 `.img`)| **SCI0**(1989 原名 *Hero's Quest*)| 腳本內嵌字串 + 部分 `TEXT` 資源 | 需先從軟碟映像抽 SCI0 資源 |
| **VGA** | `QfG1.zip`(散裝 SCI 資源)| **SCI1.1**(1992 重製)| `.MSG`(對白訊息)+ `.SCR`/`.HEP`(腳本內嵌字串)+ `FONT` 資源 | `SCIDHUV.EXE` = SCI1.1 直譯器 |

VGA 版可見 `815.MSG`、`95.MSG`、`29.MSG` 等訊息資源,以及大量 `*.SCR`/`*.HEP`。

---

## 2. ScummVM SCI 引擎 CJK 現況(已核實,讀 `qog-2/scummvm-src`)

| 事實 | 位置 | 意義 |
|---|---|---|
| 已有 `GfxFontKorean`(韓)、`GfxFontSjis`(日)引擎字型類別 | `engines/sci/graphics/fontkorean.*`、`fontsjis.*` | 雙位元組外掛點陣字型的**渲染路徑已存在** |
| CJK 字型切換點 | `graphics/cache.cpp:70-74` | 韓:`fontId==1001 && KO_KOR`;日:`fontId==900 && JA_JPN`。**加繁中在此加一分支** |
| 雙位元組排版/換行分支 | `graphics/text16.cpp`(462/464/478/484/584/598)、`paint16.cpp:595` | 需平行補 `ZH_TWN` 分支 |
| **`Graphics::Big5Font` 現成**(16px 繁中,`loadPrefixedRaw`/`drawBig5Char`/`hasGlyphForBig5Char`)| `graphics/big5.{h,cpp}` | 繁中繪字原語**不用自己寫**,其他引擎已在用 |
| `Common::ZH_TWN` 語言 enum 已存在(`tw`/`zh_TW`/Traditional)| `common/language.cpp:60` | 語言註冊現成 |
| SCI 引擎目前**無**任何 Chinese/Big5 支援 | grep 全空 | 這是我們要新增的部分 |

**韓文範式(`fontkorean.cpp`)拆解**:`GfxFontKorean` 建構時 `Graphics::FontKorean::createFont("korean.fnt")` 載入 ScummVM 共用點陣字檔(裝在 `fonts-cjk.dat`);`isDoubleByte()` 用 lead byte `0xA1–0xFE` 判雙位元組。繁中照做:包 `Big5Font`、lead byte 用 Big5 範圍(`0x81–0xFE`)。

---

## 3. 技術路線(建議)

### 3a. 引擎修改(C++,走 docker 編譯)
1. 新增 `GfxFontChinese`(仿 `GfxFontKorean`),內部包 `Graphics::Big5Font`,載入烘好的繁中點陣字。
2. `cache.cpp` 加分支:`fontId == <目標 FONT id> && getLanguage() == Common::ZH_TWN` → `new GfxFontChinese`。
3. `text16.cpp` / `paint16.cpp` 的 `KO_KOR`/`JA_JPN` 雙位元組分支,平行補 `ZH_TWN`(字寬 16、換行、行距)。
4. detection / metaengine:讓 QFG1 EGA/VGA 能被辨識為 `ZH_TWN` 變體(或用 config 覆蓋語言)。

### 3b. 字型烘製
- 沿用 qog-2 的 `build_cjk_font.py` 思路,但**輸出格式改成 `Big5Font::loadPrefixedRaw` 吃的 prefixed raw**(16px 高、Big5 索引)。
- 只需烘出遊戲實際用到的字(翻譯定版後做子集),縮小體積。

### 3c. 文字抽取 → 翻譯 → 回填
- **VGA/SCI1.1**:`.MSG` 訊息資源抽字翻譯後,以**散裝 patch 檔**(如 `815.msg`)放遊戲目錄覆蓋原資源(ScummVM SCI 支援 loose patch override,免改 RESOURCE.000)。`.SCR`/`.HEP` 內嵌字串較難(在編譯後腳本內),需 SCI 工具(SCI Companion / `sci` 反組譯)。
- **EGA/SCI0**:先從軟碟 `.img` 抽資源,文字位置與 SCI1.1 不同,工具鏈另評估。

### 3d. 交付
- 依 CLAUDE.md:**中文化僅放 ScummVM patch**(散裝 patch 檔 + 繁中字型資料 + 改過的 ScummVM 引擎 build),不散布原遊戲資源。

---

## 4. EGA vs VGA 工作量差異

- **VGA(SCI1.1)建議先做**:文字集中在 `.MSG`、patch override 機制成熟、SCI1.1 引擎路徑與韓文範本最接近。投報最高。
- **EGA(SCI0)風險較高**:需先解軟碟映像、SCI0 文字抽取工具鏈不同、text16 早期路徑可能要額外處理。建議 VGA 打通後再攻 EGA(但依 rule 83 完整性優先,兩版都要交付,不砍)。

---

## 5. 與 qog-2 可借鏡 / 不可借鏡

| 可借鏡 | 不可借鏡(引擎不同)|
|---|---|
| 字型烘製 pipeline(`build_cjk_font.py`)| AGS `.tra`/`.trs` 翻譯格式 → SCI 用 MSG/patch |
| 術語表紀律(CONTEXT.md glossary)| AGS 繪字 hook → SCI `cache.cpp`/`text16.cpp` |
| docker 交叉編譯 + 多平台打包經驗 | AGDI VGA remake 的美術/room 字 |
| ScummVM data 檔打包雷(15 個 data 檔、`fonts-cjk.dat`)| — |

---

## 6. 風險與未知(待核實,勿當定論)

1. **`.SCR`/`.HEP` 內嵌字串抽取難度**:編譯後腳本內的字串修改需 SCI 專用工具,尚未驗證回填流程。→ 下一步做 spike。
2. **EGA/SCI0 文字位置與工具鏈**:尚未抽軟碟映像確認。
3. **QFG1 FONT resource id**:韓文用 1001、日文用 900;QFG1 實際用哪個 FONT id 當主字型,需抽資源確認,才知道 `cache.cpp` 分支條件怎麼寫。
4. **上游是否已有 Chinese SCI 支援**:本 checkout 無,但較新 ScummVM 可能已加(某些中文 fan translation)。應查上游 master,能沿用就不自己造。
5. **半形/全形混排、標點、換行**:text16 的行寬與 word-wrap 對全形字的處理,需實測。

---

## 7. 建議下一步(里程碑)

- **M0(本階段完成)**:可行性確認 ← 現在這裡。
- **M1 spike(建議先做)**:抽 VGA 資源(RESOURCE.MAP/000)→ 確認 FONT id、抽一個 `.MSG`(如 `815.MSG`)→ 手翻幾句 → 烘最小 Big5 字型 → 引擎加 `ZH_TWN` 最小分支 → docker 編 ScummVM → **實機看到一句繁中對白**。這條端到端打通,其餘是量的問題。
- **M2**:VGA 全量抽字、術語表、翻譯、回填。
- **M3**:EGA 版。
- **M4**:多平台打包 + 交付。
