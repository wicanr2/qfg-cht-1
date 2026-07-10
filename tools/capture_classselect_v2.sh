set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
mkdir -p /out/shots /out/logs
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 110 ./scummvm --path=/game --auto-detect --language=tw > /out/logs/csel2.log 2>&1 &
SV=$!
# 前 ~76.5s ESC+點擊 跳過 intro/credits 到職業選擇(沿用已驗證過能到職業選擇的節奏)
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null||true; xdotool mousemove 320 240 click 1 2>/dev/null||true; done
# 前次觀察:76.5s 時畫面仍在片頭 credits→職業選擇 的轉場(wipe)中,純等待讓轉場走完(不再按鍵,避免誤觸退回選單)
sleep 6
# 到達職業選擇 —— 先截「無 hover」預設banner狀態
import -window root /out/shots/v2_banner.png 2>/dev/null||true
# hover 左雕像(戰士),盡快截圖(不點擊)
xdotool mousemove 130 200 2>/dev/null||true
sleep 0.6
import -window root /out/shots/v2_hover_l.png 2>/dev/null||true
sleep 0.6
import -window root /out/shots/v2_hover_l2.png 2>/dev/null||true
# 移到中間雕像(法師)
xdotool mousemove 300 200 2>/dev/null||true
sleep 0.6
import -window root /out/shots/v2_hover_m.png 2>/dev/null||true
sleep 0.6
import -window root /out/shots/v2_hover_m2.png 2>/dev/null||true
# 移到右雕像(盜賊)
xdotool mousemove 470 200 2>/dev/null||true
sleep 0.6
import -window root /out/shots/v2_hover_r.png 2>/dev/null||true
pkill scummvm 2>/dev/null || true
wait $SV 2>/dev/null || true
echo DONE
