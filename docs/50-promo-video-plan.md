# 推廣影片規劃 v2(納入完整 baked-art)

> 現有 `out/video/qfg1_cht_promo.mp4`(v1,44s)是在**裝飾性 baked-art 完成前**做的,只呈現版權框與角色創建。v2 要把新完成的全部美術字中文化(主選單、職業選擇、標題火焰字、credits)都秀出來,讓「連烘進美術圖的字都翻了」這個賣點更有說服力。

## 目標與規格
- 長度:**50–60s**(比 v1 長一點,容納新畫面)。
- 解析度 1280×720、25fps、h264+aac。
- 配樂:**原版 QFG1 AdLib 主題**(`out/music/qfg_bgm.wav`,已錄製;afade 進 2s / 出 3s)。**素材鐵則(rulebook 93):配樂與畫面一律用原版,不自產、不換非原版音樂**。
- 風格延續 v1:QFG 羊皮紙主題色(`#241a0c`/`#c9a227`/`#f2ead2`)、NotoSerifCJK 襯線、靜態卡 + fade(**不用 zoompan**,避免幀數爆炸;`--cpus=2 -preset veryfast`)。

## 需補拍/準備的素材(中/英對照)
新 baked-art 都要「英文原版 ▶ 繁體中文化」對照,故英文版截圖需用**未套 patch 的遊戲目錄**(`extract/vga_lc`)另拍一次:

| 畫面 | 中文截圖(已有/可重拍) | 英文截圖(補拍) |
|---|---|---|
| 主選單(海報+按鈕) | `out/shots/menu_A.png` | 需拍(vga_lc) |
| 職業選擇(戰士/法師/盜賊) | 重拍(hover 顯示標籤那刻) | 需拍 |
| 標題火焰字(所以你想當英雄?) | 需抓準確幀 | 需拍 |
| Credits(中文頭銜) | `out/shots/cr_*.png` | 需拍 |
| 角色創建(已用於 v1) | `out/video_src/vga_charcreate_cht.png` | 已有 |

> 補拍用 `tools/capture_gfxlog.sh` / `capture_charcreate.sh` 的導航;英文版把遊戲目錄換 `extract/vga_lc`、拿掉 `--language=tw`。

## 分鏡(v2,約 10 段)
1. **標題卡**:英雄傳奇 I / Quest for Glory / 繁體中文化 · EGA + VGA 雙版本(同 v1)。
2. **主選單 slide**:中文選單(徵求英雄海報 + 序章/新英雄/繼續),字幕「連主選單的手寫海報都重繪成中文」。
3. **主選單 before/after**:英文 ▶ 中文(海報 Wanted Hero ▶ 徵求英雄)。
4. **職業選擇 before/after**:choose your character / fighter·magic user·thief ▶ 選擇你的英雄 / 戰士·法師·盜賊。
5. **角色創建 before/after**:屬性羊皮紙(沿用 v1,已修 Points 殘留)。
6. **標題火焰字**:So You Want To Be A Hero ▶ 所以,你想當英雄?(短停,秀火焰字)。
7. **VGA 版權框 before/after**(沿用 v1)。
8. **Credits slide**:中文頭銜滾動(創意總監/導演/製作人…人名保留),字幕「連工作人員表的頭銜都中文化」。
9. **EGA 畫面**:EGA 版權框 + 一段 EGA 對白(證明兩版都做)。
10. **技術/結尾卡**:「VGA 4521 + EGA 3883 則對白 · 全 baked-art 中文化 · 自製 SCI view/pic 編碼器」→ github.com/wicanr2 CTA。

## 製作
- 擴充 `tools/make_promo.sh`(v1 已有 `card()/slide()/split_ba()/kb()` 函式),新增第 3/4/6/8 段的素材與字幕,調整每段秒數使總長 ~55s。
- 產出 `out/video/qfg1_cht_promo_v2.mp4`。**影片與配樂含原版版權素材 → gitignore,不入庫、不上公開 Release**(同 v1;僅本機/私下分享)。
- 合成後抽 4–6 幀讀圖檢查:標題不糊、字幕不裁、before/after 對齊、火焰字幀正確。

## 待你確認
- 這份規劃 OK 就**直接產出 v2**(補拍英文對照 → 擴充 make_promo.sh → 合成 → 抽幀把關)。
- 或先只補拍素材、你看過再合成。
