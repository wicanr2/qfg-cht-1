# Baked 美術字 UI 中文化:現況評估與路線

> 狀態:調查完成,待定路線(2026-07-09)。

## 問題

部分 UI 的靜態標籤不是文字資源,而是**烘進圖檔的點陣美術字**,文字 pipeline 無法涵蓋:

- **角色創建畫面**:屬性/技能名 `Strength` `Intelligence` `Agility` `Vitality` `Luck` `Magic` `Weapon Use` `Parry` `Dodge` `Stealth` `Pick Locks` `Throwing` `Climbing` `Name:` `start` `cancel`(數字是動態文字、會翻)。
- **標題畫面**:`Wanted Hero for the Village of Spielburg`(pic 100)。
- **開場 credits** 花體字、**職業選擇 banner**。

## 已查證(engine 加 `SCI_DUMP_PIC` / `SCI_LOG_GFX` dump 各 pic)

- 這些標籤在 **任何解壓文字資源(message/text/script/heap/font)都查無明文** → 確定是美術。
- 標題「Wanted Hero」在 **pic 100**(背景圖,字烘在圖裡)。
- 角色創建羊皮紙**不是背景 pic**(該畫面沒有新 drawPicture;pic 1=Sierra logo、100=標題、400/750=前導、902/903/905=credits)→ 判定為 **VIEW cel 疊繪**。

## 兩條路線(擇一)

### A. 改 VIEW/PIC 美術(native,正統)
抽 view/pic → 解碼成圖 → 重繪中文標籤 → 重編回 SCI patch 資源。
- 優點:與原畫面融為一體、最自然;走 ScummVM patch 交付。
- 缺點:**要寫 SCI view/pic 編解碼**(解碼可借 ScummVM;**編碼**是硬骨頭,SCI Companion 是 GUI/Windows 工具,headless 需自製 encoder);重繪要符合中世紀羊皮紙美術風格,逐螢幕做。工作量大。

### B. 引擎疊繪中文(pragmatic,自製)
`ZH_TWN` 時偵測特定畫面(角色創建等),在已知座標用 `GfxFontChinese` 疊上中文標籤(先鋪羊皮紙底色矩形蓋住英文,再畫中文)。
- 優點:**完全不碰 SCI 美術 codec**,全在引擎控制;可重用既有 Big5 繪字。
- 缺點:座標/畫面偵測**逐螢幕硬編**、較脆;底色矩形需調到貼近羊皮紙;非「原生美術」。

## 工具(已建)

- engine `SCI_LOG_GFX`:log 每次 drawPicture 的 pic id。
- engine `SCI_DUMP_PIC=<dir>`:把每張畫完的 pic(display buffer + 調色盤)dump 成 PPM,供識別/比對。
- 待建(依路線):view dump→PNG、SCI view 編碼器(路線 A);畫面偵測 + 座標表(路線 B)。

## 建議

先做 **B(引擎疊繪)** 打通角色創建畫面當 spike(投報快、不卡 SCI codec),驗證觀感;若要求「原生美術」再評估 A。
