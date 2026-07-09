# 引擎繁中化 patch:ScummVM SCI 的 `ZH_TWN` + Big5 路徑

> 狀態:M1 spike 已實機驗證(見 `images/m1-spike-copyright-cht.png`)。

## 設計總覽

不改動、不重打包 SCI 原始資源。改法分兩層:

1. **繪字層**:當遊戲語言為 `Common::ZH_TWN`,把每個 SCI font 包成 `GfxFontChinese`:
   - 單位元組(ASCII / 控制碼)→ 委派原 `GfxFontFromResource`(英文/UI 像素不變)。
   - 雙位元組(Big5 lead byte `0x81–0xFE`)→ 用 ScummVM 共用的 `Graphics::Big5Font` 畫 16px 繁中字,
     透過 `GfxScreen::putFontPixel` 寫入(尊重 SCI 的 screen/upscale 模型)。
   - 不走 PC-98/韓文的 hi-res gfx-driver 機制;採 sherlock/darkseed 的「低解析直接畫 Big5」路線。

2. **文字替換層**(採使用者建議,以 TSV 維護,不解壓/回填資源):
   - `GfxText16::Box`(訊息框必經點)在渲染前用**原文英文字串當 key** 查譯文表,命中就換成 Big5 譯文。
   - 譯文表 = runtime `translation.tsv`(英文 `\t` Big5 bytes),開機載入成 HashMap。

## 觸發語言

`SciEngine::getLanguage()` 讓 `--language=tw`(config `language` 解析為 `ZH_TWN`)覆蓋偵測語言,
免為每個中文化遊戲加 detection 條目即可套用。production 可改為正式 detection variant。

> 注意:ScummVM CLI 的語言代碼是 **`tw`**(不是 `zh_TW`);`--language=zh_TW` 會被 CLI 拒絕。

## 改動檔案(`patches/`)

| 檔 | 改動 |
|---|---|
| `graphics/fontchinese.{h,cpp}` | **新增** `GfxFontChinese`(ASCII 委派 + Big5 繪字) |
| `graphics/cache.cpp` | `getFont()`:`ZH_TWN` 時包 `GfxFontChinese` |
| `graphics/text16.cpp` | `Box()`:`ZH_TWN` 時用 `getChtTranslation()` 換字串 |
| `sci.cpp` / `sci.h` | `getLanguage()` 覆蓋、`loadChtTranslation()`、`getChtTranslation()`、`SCI_DUMP_RES` 抽字 hook |
| `module.mk` | 編 `fontchinese.o` |

`patches/0001-sci-cht-zh_twn.patch` = 對既有檔的 unified diff;`fontchinese.{h,cpp}` 為新檔整檔。

## 抽原文工具(build-time)

引擎的 `SCI_DUMP_RES=<dir>` 環境變數會用 ScummVM 自身的 SCI 解壓器,把 text/message/font/script/heap
資源 dump 成未壓縮 patch 檔(供建立 `translation.tsv` 的英文 key),dump 完即結束、不進遊戲。
這是開發工具,不影響正式遊玩路徑。

## 已知待優化(M2)

- 全形標點(`,` `、` `:`)垂直位置偏高、字面偏小 → 烘字時依字型 ascent 做垂直定位。
- 14px 筆畫略細/略糊 → 評估改 16px、或換小尺寸點陣友善字型、或加 outline 提升可讀性。
- `GfxText16` 目前只 hook `Box`;其他文字入口(`DrawString`/狀態列/選單)待 M2 一併 hook。
