# VGA baked-art patches

角色創建畫面(character creation)的美術字中文化 ScummVM loose patch。
放進 VGA 遊戲目錄即生效(與 translation.tsv / qfg1_big5.fnt 並存)。

- `904.p56` — pic 904(角色創建羊皮紙背景):13 個屬性/技能名 + Name:/Experience/Health/Stamina/Magic Points 重繪成中文明體。
- `802.v56` — view 802:start→開始、cancel→取消、Points Available→可分配點數。

由 `tools/sci_view.py`(pic-encode / encode)產生。字級 9px(貼合 ~11px 列距),
用原 pic/view 的 embedded palette 既有色。細節見 `docs/40-baked-art-ui.md`。
