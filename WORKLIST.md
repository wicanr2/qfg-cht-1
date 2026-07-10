# 英雄傳奇 I 繁中化 — 工作交接 / worklist(截至 2026-07-09)

repo:`github.com/wicanr2/qfg-cht-1`(main,已 push)。工作目錄 `~/scummvm/qfg-1/workplace`。

## 現況快照

| 里程碑 | 狀態 |
|---|---|
| M0 可行性 | ✅ 可行(`docs/00-feasibility.md`) |
| M1 端到端打通 | ✅ 引擎 `ZH_TWN`+Big5 + TSV 內容替換,實機驗證 |
| **M2 VGA 全文字中文化** | ✅ **4480/4521 則(99%)** 對白/敘述/訊息 |
| M2 古風字型 | ✅ AR PL UMing TW 明體 15px,烘 2486 字 Big5 |
| **路線A view/pic 編碼器** | ✅ `tools/sci_view.py`(view),view 908 spike 實機驗證(cel→「英雄」) |
| **M3 EGA 文字中文化** | ✅ **3878/3883(99%)**,1561 沿用 VGA + 2317 haiku;實機驗證版權文 |
| M2-D VGA baked-art 重繪 | 🔲 **進行中**:角色創建 = pic 904(13 屬性名)+ view 802(start/cancel/Points Available) |
| M4 多平台打包 | 🔲 未開始 |

## VGA baked-art 已識別(角色創建畫面)
- **pic 904**(320×200 背景圖):烘了 13 個屬性/技能名(Strength/Intelligence/…/Climbing)+ Name:/Experience/Health/Stamina/Magic Points。→ 需 **pic 編輯**(`sci_view.py` 目前只做 view,要加 pic 模式)。
- **view 802**:start(loop3/cel0 82×13 @9,157)、cancel(loop4/cel0 82×14 @9,170)、Points Available(loop7/cel0 110×14 @102,140)+ 屬性小雕像 + mnemonic 疊字。→ 用 `sci_view.py encode --replace`。
- **EGA 版角色創建屬性名 = 純文字(text.204)**,已隨 M3 文字化,不必改圖。

## EGA 待補
- 只抽了 `text.*`(3883 則)。EGA 部分對白/字串可能在 `script.*` 內嵌(grep 命中),需檢查覆蓋、補抽。
- 實機驗證更多 EGA 畫面(對白/選單);\n 硬換行畫面觀感。

## 交付原則(硬)
- 中文化**僅放 ScummVM patch**:引擎改動(`patches/`)+ `dist/`(translation.tsv + qfg1_big5.fnt)+ view/pic patch。原遊戲資源不入庫。
- 完整性:EGA/VGA 兩版都要交付。

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
