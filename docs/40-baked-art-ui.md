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

## 路線 A 進度(2026-07-09)

### 已完成:抽取/識別工具(engine hooks,全走 ScummVM 自身 decoder)
- `SCI_DUMP_ALLVIEWS=<dir>`:啟動時把**全部 view**(6678 cel)解碼 dump 成 PPM,確定性、不靠導航。
- `SCI_DUMP_VIEW` / `SCI_DUMP_PIC` / `SCI_LOG_GFX`:執行期 dump/記錄。
- 已識別範例:**view 908** = 標題副標「SO YOU WANT TO BE A HERO」發光動畫(8 cel);
  類別 banner(fighter/magic user/thief)、角色創建屬性標籤為其他 view(待逐一比對 6678 cel PPM)。

### 已確認:SCI1.1 VGA cel 格式(來自 ScummVM `unpackCelData`)
- SCI1.1 VGA cel 用**雙流**:RLE control 流(`offsetRLE`)+ literal 像素流(`offsetLiteral`)。
- RLE control byte = `XXYYYYYY`:
  - `00` copy 接下來 `YYYYYY` 個 literal 像素;`01` copy `YYYYYY+64` 個。
  - `10` 把接下來 `YYYYYY` 像素填成 literal 流的下一個 byte 值(RLE run)。
  - `11` skip `YYYYYY` 像素(透明,clearKey)。

### ✅ 已完成:SCI1.1 view 解碼/編碼器 `tools/sci_view.py`(2026-07-09,已把關)

end-to-end 驗證通過:round-trip 逐像素相符(對 ScummVM 自身 decoder)、view 908 spike 把 cel 0
換成「英雄」中文 → 編出 `908.v56` patch → **實機引擎載入覆蓋生效**(重 dump bytes 不同、cel 變中文)。

**關鍵格式事實(從 ScummVM 源碼查證,非猜測):**
- SCI1.1 VGA view header:`headerSize=u16LE(0)+2`、`loopCount=u8(2)`、`paletteOffset=u32LE(8)`、
  `loopSize=u8(12)`、`celSize=u8(13)`(view 908 的 celSize=**36**,非直覺的 32;assert 只要求 ≥32)。
- cel table entry:width/height/displaceX/displaceY 在 0/2/4/6(i16 LE)、clearKey 在 byte 8、
  `offsetRLE` 在 24(u32)、`offsetLiteral` 在 28(u32)。
- embedded palette 依 `GfxPalette::createFromData()` SCI1.1 分支(palOffset=37、colorStart=data[25]、
  count=u16LE(29)、format byte 在 data[32])。
- **loose view patch header**(最需小心):`ResourceManager::processPatch()` 對 view(SCI11)算
  `patchDataOffset = 2 + byte@offset3 + 22 + 2`;把 offset3 的 extra-header byte 設 0 → 固定 **26-byte header**
  (byte0=`0x80`,其餘補零)+ raw view data。**與 `SCI_DUMP_RES` 的 2-byte wrapper 不同**。
  patch 副檔名 = `v56`(`s_resourceTypeSuffixes`),故檔名 `908.v56`。

**`tools/sci_view.py` 指令**(走 docker uv):
- `decode <view> <outdir> --view-id <id>`:每 cel dump 成 PNG+PPM。
- `verify <view> <ref_dir> --view-id <id>`:對照 PPM,不符 exit≠0。
- `roundtrip <view> [--output raw] [--patch out]`:decode→原封重編→decode,斷言 identity。
- `encode <view> <out> [--replace loop,cel,png ...] [--patch]`:重編,可換入 RGBA PNG(alpha 0→透明/clearKey);
  `--patch` 包成 26-byte header 的 loose SCI patch。

### 下一步:scale 到各 baked-art 標籤
規格:讀原 view → 解碼各 cel → 換掉目標 cel 的 bitmap(改好的中文圖,RGB→palette index)→
**全 literal run 重編**(每列用 `00/01` control + literal 流,透明像素用 `11` skip)→ 重組 view 資源
(header/loop 表/cel 表/embedded palette,offset 全部重算)→ 輸出 loose view patch(`<id>.v56`/ScummVM SCI patch)。
- 避開自寫 RLE 壓縮:除透明用 `11` skip 外,一律 `00/01` literal(等同未壓縮),ScummVM 照樣解。
- palette:沿用原 view 的 embedded palette(中文重繪時限定用原 palette 既有色,避免 RGB→index 失真)。
- 驗證迴圈:編出 patch → 放遊戲目錄 → `SCI_DUMP_ALLVIEWS` 或實機 → 比對渲染。
- spike 目標:先換 **view 908** 一個 cel 成中文,end-to-end 驗證編碼器,再 scale 到各標籤(重繪可分派)。

> 路線 B(引擎疊繪)已評估為備案,見上；使用者選 A(原生美術)。

### ✅ 已完成:SCI1.1 pic(背景圖)解碼/編碼器,擴充進 `tools/sci_view.py`(2026-07-10)

pic 904(角色創建畫面背景,320×200,烘了全部 13 個屬性/技能名 + Name:/Experience/Health/Stamina/Magic
Points)end-to-end 驗證通過:解碼與 `out/pics/pic_904.ppm` 逐像素相符、round-trip 逐像素相同、
把 "Strength" 換成「力量」編出 `904.p56` patch,**放進 spike 遊戲目錄用真實引擎驗證生效**(重
dump 的 `pic.904` bytes 不同、`SCI_DUMP_PIC` 重 dump 出的畫面 + `import -window root` 實機截圖都
顯示中文)。

**pic 的 visual bitmap 就是一個 cel,重用了 view 的 cel RLE 解碼/編碼函式**(`unpack_cel_bitmap`/
`encode_cel_streams`),只加了 pic 的外層結構解析與重組(`SCIPicture`/`rebuild_pic`)。

**關鍵格式事實(從 ScummVM 源碼查證,非猜測):**
- pic header(`drawSci11Vga()`,picture.cpp):`headerSizeField=u16LE(0)` 必為 `0x26`(這正是
  `GfxPicture::draw()` 用來分辨「這是 SCI1.1 VGA pic」的判斷值)、`priorityBandCount=byte(3)` 必為
  14、`hasCel=byte(4)`、`vectorDataOffset=u32LE(16)`、`paletteDataOffset=u32LE(28)`、
  `celHeaderOffset=u32LE(32)`;priority band 表在 offset 40 起,`priorityBandCount*2` bytes。
- cel header(在 `celHeaderOffset`):`width=u16LE(+0)`、`height=u16LE(+2)`、`offsetRLE=u32LE(+24)`、
  `offsetLiteral=u32LE(+28)`——**與 view 的 per-cel table entry 欄位配置完全相同**。
- **SCI1.1 pic 的 clearColor 寫死為白色 `getColorWhite()`(index 255)**,不管 cel header 寫什麼
  (`drawCelData()` 明文寫死,非猜測)。
- **pic 904 的 embedded palette 只覆蓋 index 0..247**(`color_start=0 color_count=248`),
  index 255(白)、其餘未覆蓋 index 靠 `GfxPalette` 建構子的預設值(`palette16.cpp`:index 0
  預設黑、index 255 預設白,除非被合併覆蓋)。逐像素比對 `pic_904.ppm` 才抓到這點——一開始土法解碼
  少了這個預設,index 255 誤算成黑色,對不上參考圖。
- **畫面上方 10 px 是「狀態列」,不屬於 pic 資料本身**:pic 904 的 cel 高度是 190,不是 200
  (200−190=10)。查證來源:`ports.cpp` `GfxPorts::GfxPorts()` 預設 `int16 offTop = 10;`,QFG1VGA
  的 `switch` 只針對 **Mac** 版狀態列大小的特例做調整,PC/ScummVM 版維持預設 10——即 pic 906 這類
  「全螢幕背景」實際畫在 screen y=10..199,y=0..9(狀態列)完全不被 `drawPicture()`/`clearScreen()`
  碰到。這個事實只能從 `ports.cpp` 找到,pic 資源本身的 header **不記錄**這個位移。
  `tools/sci_view.py` 的 `pic-decode`/`pic-encode` 因此固定用 320×200 全螢幕畫布(對應
  `SCI_DUMP_PIC` 抓到的畫面,也是使用者要編輯的完整可視畫面),`pic-encode --replace` 吃一張
  320×200 PNG,只把 y=10..199 這段切出來重編回 cel bitmap。
- pic 904 檔案內部區塊順序(供 `rebuild_pic()` 重排 offset 用):`[固定 header+priority band
  0:72] [cel header 72:114] [RLE 114:5168] [literal 5168:57188] [palette 57188:57975]
  [vector data 57975:57976(僅 1 byte,0xFF 結束符,不畫任何東西)]`。
- **`.p56` loose patch header 算法與 view 的 `.v56`完全相同**:`ResourceManager::processPatch()`
  對 `kResourceTypePic`、`_volVersion < kResVersionSci2`(QFG1VGA 成立)的分支公式與 View 一致
  (`2 + byte@offset3 + 22 + 2` = 26-byte header),差異只在 patch type byte(pic 用 `0x81`,
  `0x81 & 0x7F == 1 == kResourceTypePic`)與副檔名(`p56` 而非 `v56`,查 `s_resourceTypeSuffixes`)。

**`tools/sci_view.py` 新增指令**(走 docker uv,同 view 指令模式):
- `pic-decode <pic> <out.png|out.ppm>`:解碼成 320×200 全螢幕 PNG/PPM(含硬編碼的頂部 10px 狀態列黑色)。
- `pic-verify <pic> <ref.ppm>`:對照參考 PPM(如 `out/pics/pic_904.ppm`),逐像素比對,不符 exit≠0。
- `pic-roundtrip <pic> [--output raw] [--patch out]`:decode→原封重編→decode,斷言 cel bitmap 與全畫布渲染皆 identical。
- `pic-encode <pic> <out> --replace <edited_320x200.png> [--patch]`:把整張 visual 換成改過的
  PNG(RGBA,alpha=0→clearColor/透明),重算 celHeader/RLE/literal/palette/vector 的 offset,
  `--patch` 包成 26-byte header 的 loose `.p56` patch(patch type `0x81`)。

**卡關記錄**(留供之後 scale 到其他 pic 時參考):第一版直接用 pic 自己的 embedded palette 上色,
index 255 對不上(誤算黑色);加上 sysPalette 建構子預設(0→黑、255→白)後仍差 10 行,才發現
`ports.cpp` 的 `offTop=10` 狀態列位移——兩次都靠**逐像素比對 `pic_904.ppm` 抓出第一個不符 byte**
定位到根因(而非憑印象猜測),符合「先查證再斷言」的原則。
