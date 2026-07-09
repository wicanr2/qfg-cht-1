export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 100 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/gfx.log &
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null; done
sleep 2; xdotool mousemove 300 220 click 1 2>/dev/null; sleep 4; xdotool key Return 2>/dev/null
sleep 6
pkill scummvm 2>/dev/null; sleep 1
grep "drawPicture" /tmp/gfx.log | awk '{print $NF}' | uniq
