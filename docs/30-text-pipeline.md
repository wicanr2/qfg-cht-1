# 文字抽取 → 翻譯 → 回填 pipeline（VGA / SCI1）

> 狀態:M1 spike 進行中。以下為已核實事實(rule 62/65,對 RESOURCE.000 驗證過)。

## 已確認事實(VGA / QfG1.zip)

- **引擎版本**:SCI1(`RESOURCE.MAP` entry=6 bytes,offset 僅可被 6 整除;非 SCI1.1)。`VERSION`=2.000。
- **主資源**:`RESOURCE.000`(6.5MB)+ `RESOURCE.MAP`。散裝 `*.SCR/*.HEP/*.MSG` 為 patch override。
- **資源清單**(`tools/sci_map.py` 解析,已對 RESOURCE.000 資源頭驗證):
  - **font**:id `0, 1, 3, 4, 123, 300, 999, 2107`(8 個)
  - **message**:105 個(含 815/814/811/804 等大對白;散裝 `815.MSG`/`95.MSG`/`29.MSG`)
  - **text**:10 個(`0, 331, 340, 600, 601, 943, 952, 990, 993, 999`)
  - view 300、pic 84、script 251。
- **資源頭格式驗證**:font 頭 = `0x87`(font=7 |0x80) + `u16 id`;message 頭 = `0x8f`(15|0x80) + `u16 id`。實測 font 4=`87 04`、font 2107=`87 3b 08`、msg 815=`8f 2f 03`,全部吻合。
- **散裝 vs volume**:散裝 `815.MSG` 頭 `8f 00`(type, headerSkip=0)後接未壓縮資料;volume 內 `8f 2f 03 ...`(type,id,packedSize,unpackedSize,compression)可能壓縮。→ **翻譯走散裝 patch 檔**(未壓縮、ScummVM 優先載入,免動 RESOURCE.000)。

## 待辦(M1/M2)

- [ ] MSG 記錄格式解碼(noun/verb/cond/seq/talker + text offset;參 ScummVM `engines/sci/engine/message.cpp`),寫 `tools/sci_msg.py` 抽字 + 回填。
- [ ] 決定主對白 font id(哪個 font 是遊戲 Say/Print 用的)→ 引擎 hook 對象。
- [ ] `.SCR`/`.HEP` 內嵌字串抽取(較難,編譯後腳本內,需 SCI 反組譯或 patch script 資源)。

## 工具

- `tools/sci_map.py` — SCI1/SCI1.1 RESOURCE.MAP 解析器(照 ScummVM `readResourceMapSCI1` 對齊,自動偵測 5/6-byte entry)。純 stdlib,走 docker uv 執行。
