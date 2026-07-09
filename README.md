# 英雄傳奇 I:降魔之戰 — 繁體中文化(ScummVM / SCI)

Quest for Glory I（Sierra 原版）的**繁體中文化**專案,提供 **EGA + VGA** 兩版,中文化以 **ScummVM patch** 形式交付,不散布原遊戲資源。

> 引擎:ScummVM **SCI**（非 AGS）。技術路線 = 沿用 ScummVM SCI 引擎既有的韓文/日文 CJK 範式,新增一條**繁體中文（`ZH_TWN` + Big5）**渲染路徑。

---

## 文件索引

| 文件 | 內容 |
|---|---|
| [docs/00-feasibility.md](docs/00-feasibility.md) | **可行性評估**:版本確認、ScummVM SCI CJK 現況、技術路線、風險、里程碑 |
| docs/10-terminology.md | 術語表 / 譯名對照（CONTEXT，動工後補） |
| docs/20-engine-cjk-patch.md | 引擎繪字 patch 說明（`GfxFontChinese` + `ZH_TWN` 分支，動工後補） |
| docs/30-text-pipeline.md | 文字抽取 → 翻譯 → 回填流程（動工後補） |

## 版本與素材

| 版本 | 引擎 | 文字資源 | 狀態 |
|---|---|---|---|
| VGA（1992 重製） | SCI1.1 | `.MSG` + `.SCR`/`.HEP` 內嵌 + `FONT` | 優先開發 |
| EGA（1989 原名 *Hero's Quest*） | SCI0 | 腳本內嵌 + `TEXT` | VGA 打通後接手 |

## 目前進度

- [x] M0 可行性確認（見 `docs/00-feasibility.md`）
- [ ] M1 spike:VGA 端到端打通（抽資源 → 引擎加繁中分支 → 實機看到一句繁中對白）
- [ ] M2 VGA 全量翻譯
- [ ] M3 EGA 版
- [ ] M4 多平台打包交付

## 交付原則

- 中文化**僅放 ScummVM patch**（散裝 patch 資源 + 繁中字型資料 + 改過的 ScummVM 引擎修改），原遊戲資源不入庫、不散布。
- 完整性優先:EGA / VGA 兩版都要交付（retro 完整性原則）。

## 相關專案

- 英雄傳奇 II《烈火神兵》繁中化（AGS 引擎,不同技術路線）:<https://github.com/wicanr2/quest-of-glory-ii-cht>
