export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 150 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/g.log &
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null; done
echo "=====STATUE=====" >> /tmp/g.log
sleep 2; xdotool mousemove 150 220 click 1 2>/dev/null   # 左雕像(fighter)
sleep 4; xdotool key Return 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null
sleep 6; import -window root /out/shots/id_cc.png 2>/dev/null
sleep 4
pkill scummvm 2>/dev/null; sleep 1
echo "=== 雕像點擊後繪的 view(view=id 尺寸 @座標)==="
awk '/=====STATUE=====/{m=1} m && /SCI_LOG_GFX view/' /tmp/g.log | sed 's/.*SCI_LOG_GFX //' | sort | uniq -c | sort -rn | head -40
echo "=== 之後繪的 pic ==="
awk '/=====STATUE=====/{m=1} m && /drawPicture/' /tmp/g.log | grep -o 'pic=[0-9]*' | sort -u
