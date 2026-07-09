# 英雄傳奇 I:降魔之戰 — 繁體中文化(ScummVM / SCI)

Quest for Glory I（Sierra 原版）的**繁體中文化**專案,提供 **EGA + VGA** 兩版,中文化以 **ScummVM patch** 形式交付,不散布原遊戲資源。

> 引擎:ScummVM **SCI**（非 AGS）。技術路線 = 沿用 ScummVM SCI 引擎既有的韓文/日文 CJK 範式,新增一條**繁體中文（`ZH_TWN` + Big5）**渲染路徑。

---

## 文件索引

| 文件 | 內容 |
|---|---|
| [docs/00-feasibility.md](docs/00-feasibility.md) | **可行性評估**:版本確認、ScummVM SCI CJK 現況、技術路線、風險、里程碑 |
| [docs/20-engine-cjk-patch.md](docs/20-engine-cjk-patch.md) | 引擎繪字 patch：`GfxFontChinese` + `ZH_TWN` 分支 + TSV 內容替換 |
| [docs/30-text-pipeline.md](docs/30-text-pipeline.md) | 文字抽取 → 翻譯（TSV）→ Big5 字型烘製流程 |
| docs/10-terminology.md | 術語表 / 譯名對照（CONTEXT，M2 抽字後補） |

## M1 spike 成果（已實機驗證）

啟動版權框英文原文自動替換為繁體中文，經 ScummVM SCI 文字路徑 + Big5 渲染：

| 英文原版 | 繁中化 |
|---|---|
| ![en](docs/images/m1-spike-copyright-en.png) | ![cht](docs/images/m1-spike-copyright-cht.png) |

## 版本與素材

| 版本 | 引擎 | 文字資源 | 狀態 |
|---|---|---|---|
| VGA（1992 重製） | SCI1.1 | `.MSG` + `.SCR`/`.HEP` 內嵌 + `FONT` | 優先開發 |
| EGA（1989 原名 *Hero's Quest*） | SCI0 | 腳本內嵌 + `TEXT` | VGA 打通後接手 |

## 目前進度

- [x] M0 可行性確認（見 `docs/00-feasibility.md`）
- [x] M1 spike:VGA 端到端打通（引擎 `ZH_TWN`+Big5 分支 → TSV 替換 → 實機繁中對白）
- [x] M2 VGA 全量翻譯：4521 則抽字，**4480 則已翻譯（99%）**；古風明體字型（AR PL UMing TW 15px）；2486 字 Big5 字型
- [ ] M2 收尾：校潤專有名詞一致性、hook 其餘文字入口（`DrawString`/狀態列/選單）、真人流程實測
- [ ] M3 EGA 版
- [ ] M4 多平台打包交付

### 翻譯工作流

`SCI_DUMP_RES` 抽字 → `extract_strings.py`（MessageReaderV3 精確抽 key）→ `translation/todo/*.tsv`（分批）
→ haiku subagent 翻譯 → `translation/batch/NN-auto.tsv` → `merge_translations.py`（strip 比對保留 exact key）
→ `translation/translation.tsv`（canonical worklist）→ `build_cht.py`（NORMALIZE 修非 Big5 + `corrections.tsv` 修錯譯 + 烘明體）→ `dist/`。

## 交付原則

- 中文化**僅放 ScummVM patch**（散裝 patch 資源 + 繁中字型資料 + 改過的 ScummVM 引擎修改），原遊戲資源不入庫、不散布。
- 完整性優先:EGA / VGA 兩版都要交付（retro 完整性原則）。

## 相關專案

- 英雄傳奇 II《烈火神兵》繁中化（AGS 引擎,不同技術路線）:<https://github.com/wicanr2/quest-of-glory-ii-cht>
