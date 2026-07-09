# 英雄傳奇 I 術語表 + 翻譯指南(canonical)

> 所有譯者(含 subagent)翻譯前必讀。用詞以本表為準;遇新專有名詞先查本表,沒有的沿用風格新增後回報。
> QFG1 設定於**史畢柏格山谷(Valley of Spielburg)**,歐洲中世紀奇幻風;人名地名走**德/歐系**音譯
> (與 QFG2 的阿拉伯風不同)。共通 QFG 術語對齊姊妹作 qog-2。

## 翻譯風格(硬規則)

1. **繁體中文**,語氣參照《軟體世界》1990 年代雜誌攻略:生動、口語、對玩家親切(可直呼「你」)。敘述活潑,NPC 各有語域。
2. **標點一律用全形中文標點**:`,` `。` `、` `:` `!` `?` `「」` `『』` `…` `——`。
   **絕不可用半形 `,.:!?`**(半形會走英文小字型,大小不一、破版)。
   - 省略號用 `…`(U+2026),**不要用 `⋯`**(U+22EF,不在 Big5,會遺失)。
   - 引號用 `「」`,不要用 `‘’“”`。
   - **台灣用語**,避免兒化音與中國大陸口語(如「哪兒」→「哪裡」、「一會兒」→「一下」)。
   - 原文是阿拉伯數字(如 `10 minute`)就**保留阿拉伯數字**(「休息 10 分鐘」),不要改成國字。
3. **保留原文的控制/格式碼原樣**:`%d` `%s` `%3d` 等 printf 佔位、`\n`、開頭/結尾的空白**必須原樣保留**在譯文對應位置。
4. **保留 key 完全不動**:TSV 第一欄(英文原文)絕不修改(含尾隨空白);只填第二欄中文。
5. 未能確定的專有名詞:先音譯 + 在回報裡標記待定,不要亂猜或留英文。
6. 語意優先於字面;句子通順自然,不要翻譯腔。長句可依中文習慣斷句。

## 職業 / 屬性 / 技能(對齊 qog-2)

| 英 | 中 | 英 | 中 |
|---|---|---|---|
| Fighter | 戰士 | Strength | 力量 |
| Magic User / Wizard | 法師 | Intelligence | 智力 |
| Thief | 盜賊 | Agility | 敏捷 |
| Paladin | 聖騎士 | Vitality | 體質 |
| Hero | 英雄 | Luck | 幸運 |
| Honor | 榮譽 | Health / Hit Points | 生命力 |
| Experience | 經驗 | Stamina | 耐力 |
| Mana | 法力(_避_:魔力/MP) | Weapon Use | 武器 |
| Parry | 招架 | Dodge | 閃避 |
| Stealth | 潛行 | Climbing | 攀爬 |
| Throwing | 投擲 | Magic | 魔法 |
| Lock Picking | 開鎖 | Pick Pockets | 扒竊 |
| Communication | 交涉 | Puzzle Pieces | 拼圖片 |

## 法術(spells)

| 英 | 中 | 英 | 中 |
|---|---|---|---|
| Open | 開啟術 | Detect Magic | 偵測魔法 |
| Trigger | 觸發術 | Dazzle | 眩目術 |
| Calm | 鎮定術 | Flame Dart | 火焰鏢 |
| Fetch | 取物術 | | |

## 貨幣 / 時間

- Silver(s) — 銀幣。_避_:金幣/第納爾(那是 QFG2)。
- Copper — 銅板。

## 人物(德/歐系音譯)

| 英 | 中 | 備註 |
|---|---|---|
| Baron Stefan von Spielburg | 史蒂芬·馮·史畢柏格男爵 | 山谷領主 |
| Elsa von Spielburg | 艾爾莎·馮·史畢柏格 | 男爵之女,被詛咒化為山賊首領 |
| Erana | 伊瑞娜 | 已逝的善良女法師(非阿拉伯角色,維持原音;對齊 qog-2) |
| Erasmus | 伊拉斯謨 | 巫師(對齊 qog-2) |
| Fenrus | 芬魯斯 | 伊拉斯謨的蝙蝠夥伴 |
| Baba Yaga | 芭芭雅嘎 | 女巫反派(斯拉夫傳說) |
| Yorick | 尤瑞克 | 芭芭雅嘎的弄臣僕人 |
| Abdulla Doo | 阿布杜拉·嘟 | 飛毯商人(諧趣名) |
| Shameen | 沙敏 | 卡塔族商人(對齊 qog-2) |
| Shema | 席瑪 | 卡塔族商人 |
| Aeolus | 埃俄羅斯 | 草原半人馬 |
| Toro | 托羅 | 可切磋的鬥士 |
| Dr. Cranium | 顱骨博士 | 瘋狂博士 |
| The Healer / Amelia | 治療師 / 阿蜜莉亞 | |
| Sheriff | 治安官 | 史畢柏格鎮治安官 |
| Otto | 奧圖 | 客棧老闆 |

## 種族 / 生物

| 英 | 中 | 英 | 中 |
|---|---|---|---|
| Liontaur | 獅人(對齊 qog-2) | Katta | 卡塔族 |
| Saurus | 索魯斯(_避_恐龍) | Centaur | 半人馬 |
| Cheetaur | 獵豹人 | Kobold | 地精 |
| Meep(s) | 咪普 | Antwerp | 安特衛普(彈跳怪) |
| Dryad | 樹精 | Fairy / Fairies | 妖精 |
| Brigand(s) | 山賊 | Goblin | 哥布林 |
| Troll | 巨魔 | Ogre | 食人妖 |

## 地名 / 場所

| 英 | 中 |
|---|---|
| Spielburg | 史畢柏格 |
| Valley of Spielburg | 史畢柏格山谷 |
| Adventurers' Guild | 冒險者公會 |
| Erana's Peace | 伊瑞娜的安寧之地 |
| Baba Yaga's Hut | 芭芭雅嘎的小屋 |
| Brigand Fortress | 山賊要塞 |
| Dead Parrot Inn | 死鸚鵡客棧 |
| Dragon Smoke mountains | 龍煙山脈 |

## 待補

- 抽字過程中出現、本表未列的專有名詞 → 譯者回報,由把關者(旗艦)定調後補入本表。
