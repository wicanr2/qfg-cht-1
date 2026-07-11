#!/usr/bin/env bash
set -eu
# ===== 主題 token(QFG 羊皮紙,沿用 v1)=====
BG_DEEP='#241a0c'; BG_LITE='#5a4020'; INK='#2a2010'
GOLD='#c9a227'; GOLDSH='#6e4d12'; BLOOD='#8c2a13'; CREAM='#f2ead2'; TAN='#bc954e'
FB=/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc
FR=/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc
W=1280; H=720; FPS=25; SHOT=/shots; OUT=/out; TMP=/tmp/c; mkdir -p "$TMP" "$OUT"

# 標題/結尾卡:羊皮紙徑向漸層 + 鎏金浮雕
card(){ # $1 out  $2 中標  $3 英標  $4 副標
  convert -size ${W}x${H} "radial-gradient:${BG_LITE}-${BG_DEEP}" \
    -font "$FB" -gravity center \
    -fill "$GOLDSH" -pointsize 96 -annotate +4+4 "$3" -fill "$GOLD" -pointsize 96 -annotate +0+0 "$3" \
    -fill "$CREAM" -pointsize 70 -annotate +0+100 "$2" \
    -fill "$TAN"   -pointsize 32 -annotate +0+185 "$4" "$1"; }

# 框內截圖 + 底部字幕
slide(){ # $1 out  $2 screenshot  $3 字幕
  convert -size ${W}x${H} "gradient:${BG_LITE}-${BG_DEEP}" "$TMP/bg.png"
  convert "$SHOT/$2" -filter point -resize x600 -bordercolor "$GOLD" -border 3 "$TMP/sc.png"
  convert "$TMP/bg.png" "$TMP/sc.png" -gravity north -geometry +0+18 -composite \
    -fill "#00000099" -draw "rectangle 0,646 ${W},720" \
    -font "$FR" -fill "$CREAM" -gravity south -pointsize 34 -annotate +0+26 "$3" "$1"; }

# 前後對照:左英文 右中文 + 中間金色箭頭
split_ba(){ # $1 out  $2 en.png  $3 cht.png  $4 標題
  convert -size ${W}x${H} "gradient:${BG_LITE}-${BG_DEEP}" "$TMP/bg.png"
  convert "$SHOT/$2" -filter point -resize 520x -bordercolor "#77675088" -border 2 "$TMP/l.png"
  convert "$SHOT/$3" -filter point -resize 520x -bordercolor "$GOLD"        -border 2 "$TMP/r.png"
  convert "$TMP/bg.png" \
    "$TMP/l.png" -gravity west  -geometry +40+20 -composite \
    "$TMP/r.png" -gravity east  -geometry +40+20 -composite \
    -font "$FB" -fill "$GOLD" -gravity center -pointsize 64 -annotate +0+20 "►" \
    -font "$FR" -fill "#9a8a6a" -gravity northwest -pointsize 26 -annotate +60+18 "英文原版" \
    -font "$FR" -fill "$CREAM"  -gravity northeast -pointsize 26 -annotate +60+18 "繁體中文化" \
    -font "$FB" -fill "$CREAM" -gravity south -pointsize 36 -annotate +0+24 "$4" "$1"; }

kb(){ # $1 png  $2 mp4  $3 秒  —— 靜態 + 淡入淡出(不用 zoompan)
  local FO; FO=$(awk "BEGIN{print $3-0.5}")
  ffmpeg -y -loglevel error -loop 1 -i "$1" -t "$3" -r $FPS \
    -vf "fade=t=in:st=0:d=0.5,fade=t=out:st=$FO:d=0.5,format=yuv420p" \
    -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$2"; }

# ===== 分鏡(v2:納入主選單/職業選擇/標題火焰字/credits 全部 baked-art)=====
card     "$TMP/00.png" '英雄傳奇 I' 'Quest for Glory' '繁體中文化 · EGA + VGA 雙版本 · So You Want to Be a Hero'
slide    "$TMP/01m.png" menu_cht.png '連主選單的「徵求英雄」海報,都重新手繪成中文'
split_ba "$TMP/02m.png" menu_en.png menu_cht.png '主選單 · 序章 / 新英雄 / 繼續'
split_ba "$TMP/03c.png" classsel_en.png classsel_cht.png '職業選擇畫面 · Choose Your Hero ▶ 選擇你的英雄'
slide    "$TMP/01.png" vga_charcreate_cht.png '史畢柏格山谷被詛咒了 —— 而你,想當個英雄'
split_ba "$TMP/04.png" vga_charcreate_en.png vga_charcreate_cht.png '角色創建畫面 · 前後對照'
split_ba "$TMP/05f.png" title_fire_en.png title_fire_cht.png '片頭火焰字 · 所以,你想當英雄?'
split_ba "$TMP/02.png" vga_copyright_en.png vga_copyright_cht.png 'VGA 重製版 · 全文中文化'
slide    "$TMP/07og.png" ingame_ogre_cht.png '遊戲中即時對白 · 高解析中文,逐字銳利無鋸齒'
slide    "$TMP/08vl.png" ingame_village_cht.png '村民對白 · 逐字明體,行首字完整'
split_ba "$TMP/06cr.png" credits_en.png credits_cht.png '工作人員表 · 職銜全數中文化,人名保留'
slide    "$TMP/05.png" ega_copyright_cht.png 'EGA 原版 (1989) 也一併中文化 —— 兩版都做'
card     "$TMP/06.png" '4521 + 3883 則對白' 'Fully Translated' '自製 SCI view/pic 編碼器 · 古風明體 · ScummVM patch'
card     "$TMP/99.png" '英雄傳奇 I 繁中版' 'github.com/wicanr2' '免費開源 · qfg-cht-1 · 向 Lori 與 Corey Cole 致敬'

# ===== 每段秒數 + concat =====
LIST="$TMP/list.txt"; : > "$LIST"
declare -A SEC=( [00]=5 [01m]=4 [02m]=5 [03c]=5 [01]=5 [04]=6 [05f]=5 [02]=6 [07og]=5 [08vl]=4 [06cr]=4 [05]=5 [06]=4 [99]=6 )
for f in 00 01m 02m 03c 01 04 05f 02 07og 08vl 06cr 05 06 99; do
  kb "$TMP/$f.png" "$TMP/s_$f.mp4" "${SEC[$f]}"
  echo "file '$TMP/s_$f.mp4'" >> "$LIST"
done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$TMP/silent.mp4"

# ===== 鋪原版配樂(afade in 2s / out 3s)=====
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4")
FO=$(awk "BEGIN{print $DUR-3}")
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -stream_loop -1 -i /music/qfg_bgm.wav \
  -filter_complex "[1:a]atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3[a]" \
  -map 0:v -map "[a]" -threads 2 -c:v libx264 -preset veryfast -c:a aac -b:a 192k -shortest -movflags +faststart \
  "$OUT/qfg1_cht_promo_v3.mp4"
echo "DONE: $OUT/qfg1_cht_promo_v3.mp4  ($DUR s)"

# ===== 驗證用 montage(所有分鏡 PNG,4 欄)=====
montage "$TMP/00.png" "$TMP/01m.png" "$TMP/02m.png" "$TMP/03c.png" \
        "$TMP/01.png" "$TMP/04.png" "$TMP/05f.png" "$TMP/02.png" \
        "$TMP/07og.png" "$TMP/08vl.png" "$TMP/06cr.png" "$TMP/05.png" \
        "$TMP/06.png" "$TMP/99.png" \
  -tile 4x -geometry 320x180+4+4 -background '#0c0818' "$OUT/v3_montage.png"
echo "DONE: $OUT/v3_montage.png"
