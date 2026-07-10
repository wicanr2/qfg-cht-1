# EGA baked-art patches(SCI0)

英雄傳奇 I EGA 版(Hero's Quest,SCI0 引擎)的美術字中文化 ScummVM loose patch。
放進 EGA 遊戲目錄即生效(與 translation.tsv / qfg1_big5.fnt 並存)。

- `view.100` — 主選單海報 view 100 loop0:「Wanted:Hero / for the / Village of Spielburg」→「徵求英雄 / 前往 / 史畢柏格村」。
- `view.506` — 職業選擇 view 506 loop1:「CHOOSE YOUR CHARACTER」→「選擇你的英雄」;FIGHTER/MAGIC USER/THIEF→戰士/法師/盜賊。

由 `tools/sci0_view.py`(自製 SCI0 EGA view 解/編碼器,對 ScummVM view.cpp getBitmap 逐像素驗證 + round-trip 位元組一致)產生。EGA 4-bit cel、只用原 cel 既有 EGA 色。
