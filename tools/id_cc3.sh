export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 200 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/g.log &
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null; done
echo "=====CLICK=====" >> /tmp/g.log
sleep 2; xdotool mousemove 300 220 click 1 2>/dev/null; sleep 3; xdotool key Return 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null
for s in $(seq 1 9); do sleep 5; xdotool key Return 2>/dev/null; import -window root /out/shots/cc3_$(printf %02d $s).png 2>/dev/null; done
pkill scummvm 2>/dev/null; sleep 1
echo "=====CLICK 之後所有 view/pic(去重)====="
awk '/=====CLICK=====/{m=1} m && /SCI_LOG_GFX view/{print $3}' /tmp/g.log | sort -u | tr '\n' ' '
echo
awk '/=====CLICK=====/{m=1} m && /drawPicture/{print}' /tmp/g.log | grep -o 'pic=[0-9]*' | sort -u | tr '\n' ' '
echo
