# VGA baked-art patches

角色創建畫面(character creation)的美術字中文化 ScummVM loose patch。
放進 VGA 遊戲目錄即生效(與 translation.tsv / qfg1_big5.fnt 並存)。

- `904.p56` — pic 904(角色創建羊皮紙背景):13 個屬性/技能名 + Name:/Experience/Health/Stamina/Magic Points 重繪成中文明體。
- `802.v56` — view 802:start→開始、cancel→取消、Points Available→可分配點數。

由 `tools/sci_view.py`(pic-encode / encode)產生。字級 9px(貼合 ~11px 列距),
用原 pic/view 的 embedded palette 既有色。細節見 `docs/40-baked-art-ui.md`。

## 追加(裝飾性 baked-art)
- `100.p56` — pic 100(主選單樹背景):海報「Wanted Hero for the Village of Spielburg」→「徵求英雄/為了/史畢柏格村」(inpaint 去英文 + 明體重繪)。
- `100.v56` — view 100 loop4:選單按鈕 Introduction→序章、Start New Hero→新英雄、Continue Quest→繼續(金色花體,亮金 #ffeabc→#e0af54 + 深描邊 #2a1606)。
- `506.v56` — 職業選擇畫面(choose your character)標籤,view 506:loop3/cel0 橫幅「choose your character」→「選擇你的英雄」;loop1/loop2(一般態/hover 態各 3 cel)fighter→戰士、magic user→法師、thief→盜賊(木牌雕刻風,深棕字 #4B3B1B + 淺金 highlight #D7AF6B,原木牌底色/邊框不動)。loop0/cel0(7x6 純色小圖,非文字)未動。
- `908.v56` — 標題副標 view 908(loop0/cel0..7,火焰動畫「SO YOU WANT TO BE A HERO」)→「所以,你想當英雄?」(分兩行「所以,你想」/「當英雄?」),火焰漸層 #ffe040→#ff6a10 + 深描邊 #6a2400,套用同一句到全部 8 cel(逐 cel 依尺寸 extent,背景填回原橄欖色 #6F6F13 以貼合底圖;flicker 動畫效果捨棄,8 幀文字相同)。
- `903.v56` — credits view 903,8 個有字 cel 的頭銜中文化(人名保留英文,原像素不動):loop0 Creative Director→創意總監(Bill Davis)、loop2 Executive Producer→執行製作(Ken Williams)、loop3 Director→導演(Lori Ann Cole)、loop4 Producer→製作人(Stuart Moulder)、loop7 Game Designers→遊戲設計(Lori Ann Cole/Corey Cole)、loop8 Art Designer→美術設計(Arturo Sinclair)、loop10 Lead Programmers→首席程式(Tom De Salvo/Bob Fischbach/Oliver Brelsford)、loop11 Composer→作曲(Mark Seibert)。做法:依每 cel 逐列掃描重建 alpha(magenta 透明色→alpha=0),頭銜區整段清除重繪中文,人名區像素完全保留。頭銜用**金色花體 recipe A**(亮金漸層 #ffeabc→#e0af54 + 深描邊 #2a1606,單行填滿頭銜區),與保留的金色英文人名同色系(初版曾用暗棕碳字 #4B3B1B,實機呈暗糊塊、與金色人名不搭,已改)。純裝飾 cel(loop1 天使、loop5 獅鷲、loop9 馬浮雕)未動。
