# 英雄傳奇 I：So You Want to Be a Hero — 繁體中文化 v1.0

Sierra 1989 年經典《Hero's Quest》(後改名 *Quest for Glory I*)的**繁體中文化**,**EGA 原版 + VGA 重製版都做**,以 **ScummVM patch** 形式交付。

## 內容
- **全文字中文化**:VGA 4521 則 / EGA 3883 則對白、敘述、訊息(99%,古風明體)。
- **美術字中文化(baked-art)**:主選單海報「徵求英雄」+ 按鈕、角色創建屬性/技能表、職業選擇(戰士/法師/盜賊)、標題副標「所以,你想當英雄?」、credits 頭銜。全部逐一挖除英文、重繪中文,自製 SCI view/pic 編碼器完成。

## 下載(依平台選,VGA / EGA 分開)
| 檔案 | 平台 | 版本 |
|---|---|---|
| `QFG1-CHT-VGA-x86_64.AppImage` | Linux | VGA |
| `QFG1-CHT-EGA-x86_64.AppImage` | Linux | EGA |
| `QFG1-CHT-VGA-windows-x86_64.zip` | Windows | VGA |
| `QFG1-CHT-EGA-windows-x86_64.zip` | Windows | EGA |
| `QFG1-CHT-VGA-macos-universal.dmg` | macOS(Apple Silicon + Intel universal)| VGA |
| `QFG1-CHT-EGA-macos-universal.dmg` | macOS(Apple Silicon + Intel universal)| EGA |
| `qfg1-cht-dev-setup-*.tar.gz` | 開發者 | 引擎 patch + build 腳本 |

## 使用方式
1. **自備原版遊戲**(本專案不含任何原始遊戲資源)。
2. 把包內 `cht-data-*/` 的檔案複製進你的遊戲資料夾。
3. Windows:雙擊 `玩英雄傳奇I-繁中.bat`(會提示遊戲路徑)。Linux:執行 AppImage,ScummVM 加入遊戲並以語言 `台灣中文`(`--language=tw`)啟動。

## 交付原則
中文化**僅放 patch**(引擎修改 + 中文字型/文本 + view/pic patch),**原始遊戲資源不散布**,請使用者自備正版。

## 致謝
向 **Lori 與 Corey Cole** 致敬。姊妹作:[英雄傳奇 II 繁中化](https://github.com/wicanr2/quest-of-glory-ii-cht)。
