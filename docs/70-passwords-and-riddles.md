# 英雄傳奇 I — 密碼、通關語與謎題(中文版處理說明)

QFG1 有幾處要「玩家自己打字輸入英文」才能過的關卡:盜賊公會的口令、芭芭雅嘎小屋的咒語、以及巫師 Erasmus 的三道謎題。這些輸入由 SICE 解析器(parser)比對**英文原文**,中文化無法改動解析器的比對字串——如果只把提示翻成中文、卻沒告訴玩家該打什麼英文,中文玩家就會卡死。

本文件說明中文版的處理方式,並列出全部關卡的**問題(英/中)+ 答案**。

## 中文版怎麼處理

- **原則:提示照譯,答案就地附在提示後面。** 凡是「答錯會卡關」的硬輸入點,中文譯文在問句/提示後直接補一段 `(輸入:...)`,把該打的英文原封不動寫給玩家。這樣玩家看得懂劇情,又知道解析器認得的英文該怎麼拼。
- **答案維持英文原文,不音譯、不翻譯。** 解析器比對的是英文;`schwertfisch`(德文「劍魚」)這種字若翻成中文,打進去就不會過。所以附註裡一律給原文。
- **玩笑關不硬性附答案(因為根本不會卡)。** Erasmus 的「三道謎題」是致敬《巨蟒與聖杯》的橋段,答對答錯都會被傳送進去(見下),不是真的門檻,故只在文件說明、不在遊戲內附「標準答案」誤導玩家以為必須答對。

## 一、硬輸入關(答錯會卡,已就地附答案)

| # | 情境 | 問題 / 提示(英文原文) | 中文譯文(遊戲內) | 該輸入的答案 |
|---|---|---|---|---|
| 1 | 酒館保鑣克拉舍(Crusher)擋在盜賊公會入口,問你口令 | `"WHAT IS THE THIEVES' PASSWORD?"` | 「盜賊的密碼是什麼?**(輸入:schwertfisch)**」 | `schwertfisch` |
| 2 | 要讓芭芭雅嘎(Baba Yaga)的雞腿小屋蹲下開門,需唸出咒語(VGA:腦中傳來聲音問「韻文是什麼」) | `You hear a voice in your head asking, 'What is the rhyme?'` | 「你聽到腦子裡傳來的聲音問著,『韻文是什麼?』**(輸入:Hut of Brown, Now Sit Down)**」 | `Hut of Brown, Now Sit Down` |
| 2' | 同上,EGA 版的輸入點(NPC 提示你唸咒語) | `Ok, go ahead and say the rhyme.` | 「好吧,你就說那個韻文吧。**(輸入:Hut of brown, now sit down)**」 | `Hut of brown, now sit down` |

**口令 `schwertfisch` 的來源**:遊戲中盜賊 Sneak 會告訴你「Tell Crusher that the password is 'schwertfisch'.」;此字在遊戲內固定以英文顯示,玩家順著劇情走本來就會看到,附註只是輸入當下的提醒。

**咒語的來源**:遊戲多處會揭示,例如 EGA 版「The rhyme is: 'Hut of brown, now sit down'.」。大小寫、標點不影響解析器判定,照打即可。

## 二、玩笑關:Erasmus 的「三道謎題」(不會卡,毋須背答案)

進巫師 Erasmus 家前,他會宣布「想見巫師的人必須先回答三個問題」,並問一串明顯惡搞的問題。這是向《Monty Python and the Holy Grail》致敬的橋段——**無論你答對、答錯、還是答不出來,他都會用一句雙關把你「傳送」進去**:

- 答不出來:`"Since you won't answer my riddles, to SPELL with you!"`(「to HELL with you」的法術雙關)
- 全答得出來:`"You seem to know all of my punchlines, so... to SPELL with you!"`

所以這關**不構成真正的門檻**,中文版不在遊戲內硬附「正解」以免誤導。若你想配合演出,幾道題的哏是:

| 問題(英文) | 中文譯文 | 哏 / 可接的答案 |
|---|---|---|
| `"WHAT IS THE MEANING OF LIFE, THE UNIVERSE, AND EVERYTHING?"` | 「生命、宇宙和一切的意義是什麼?」 | `42`(《銀河便車指南》) |
| `"WHAT IS THE MEAN AIR SPEED OF AN UNLADEN SWALLOW?"` | 「沒有負荷的燕子平均空中速度是多少?」 | 反問 `African or European?`(《聖杯》橋段;遊戲自己就會這樣回) |
| (問統治者是誰之類) | — | 本谷地領主男爵名 `Stefan`(Stefan von Spielburg) |

## 三、其他小提醒

- **姓名輸入**:遊戲開頭要你替角色命名,可任意輸入(建議用英文字母,存檔相容性較好)。此處非關卡,不影響通關。
- **戰鬥/施法指令**:VGA 版多以選單/圖示操作,少數情境仍可用打字下指令;若打字,動詞用英文(如 `cast`, `open`, `throw`)較穩。中文化不改解析器動詞。
- **大小寫與標點**:上述口令/咒語一律不分大小寫,標點可省略,照抄括號內文字即可。

---

相關文件:中文化方法論見 [`docs/60-sci-cht-methodology.md`](60-sci-cht-methodology.md);遊戲手冊(含劇情/操作)見 [`docs/manual/`](manual/)。
