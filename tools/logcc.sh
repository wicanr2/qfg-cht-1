export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 135 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/g.log &
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null; done
echo "--- MARK statue click ---" >> /tmp/g.log
sleep 2; xdotool mousemove 300 220 click 1 2>/dev/null; sleep 5; xdotool key Return 2>/dev/null; sleep 12
import -window root /out/shots/cc_verify.png 2>/dev/null
pkill scummvm 2>/dev/null; sleep 1
echo "=== statue click 之後繪的 view(角色創建畫面)==="
awk '/MARK statue click/{m=1} m && /SCI_LOG_GFX view/' /tmp/g.log | awk '{print $3}' | sort -u
echo "=== 之後繪的 pic ==="
awk '/MARK statue click/{m=1} m && /drawPicture/' /tmp/g.log | awk '{print $NF}' | sort -u
