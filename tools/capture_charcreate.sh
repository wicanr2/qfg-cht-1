set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 140 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
SV=$!
# 前 ~78s 狂送 ESC 跳過 intro/credits 到職業選擇
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null||true; xdotool mousemove 320 240 click 1 2>/dev/null||true; done
# 點中間(戰士)雕像
sleep 2; xdotool mousemove 300 220 click 1 2>/dev/null||true
sleep 3; xdotool key Return 2>/dev/null||true; xdotool mousemove 320 240 click 1 2>/dev/null||true
# 之後每 5s 截圖找角色創建畫面
for s in $(seq 1 8); do sleep 5; xdotool key Return 2>/dev/null||true; import -window root /out/shots/cc_$(printf %02d $s).png 2>/dev/null||true; done
kill $SV 2>/dev/null || true
