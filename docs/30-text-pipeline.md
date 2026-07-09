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

## 採用架構:TSV 內容替換(不解壓/不回填資源)

依使用者決策(2026-07-09):**不逐一解壓/回填 SCI 資源**,改用外部 TSV 讓引擎執行期做內容比對替換。
好維護、好 diff、不怕壓縮與 byte offset。

流程:
1. **抽英文原文**(build-time,一次性):引擎 `SCI_DUMP_RES=<dir>` 用 ScummVM 自身解壓器把
   text/message/script/heap dump 成未壓縮 patch → 抽出所有可見字串當 TSV 的 key。
2. **人工維護** `translation/translation.tsv`(UTF-8:`英文原文 \t 中文`)。
   - key 必須與遊戲傳給 `GfxText16` 的原文**完全一致**(含標點,不含結尾 NUL)。
3. **build** `tools/build_cht.py`:
   - 產 runtime `dist/translation.tsv`(英文 `\t` **Big5** bytes;TAB/LF 不在 Big5 → 安全分隔)。
   - 烘 `dist/qfg1_big5.fnt`(只含用到的字,對齊 `Graphics::Big5Font::loadPrefixedRaw`)。
4. **交付**:把 `translation.tsv` + `qfg1_big5.fnt` 放進遊戲目錄(ScummVM patch)。以 `--language=tw` 啟用。

## 已核實 MSG/字串位置

- 版權框(啟動自動顯示)= `message.002` 第一則,161 字元,結尾 `folks.`(spike 用它驗證)。
- `.SCR`/`.HEP` 內嵌字串:因改走內容替換,**不需**逐一回填 script;只要原文出現在 `GfxText16` 即可替換。
  (若某些字串未經 `Box`/`DrawString`,M2 再擴充 hook 點。)

## 工具

- `tools/sci_map.py` — SCI1/SCI1.1 RESOURCE.MAP 解析器(照 ScummVM `readResourceMapSCI1` 對齊)。純 stdlib。
- `tools/build_cht.py` — TSV(UTF-8)→ runtime Big5 TSV + 烘 Big5 字型(Pillow,docker uv)。
- `tools/apply_patches.sh` — 把引擎 patch 套進 ScummVM source 樹。
- 引擎 `SCI_DUMP_RES` hook — 用 ScummVM 解壓器抽原文(build-time)。
