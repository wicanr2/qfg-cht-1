set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 70 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
SV=$!
# 反覆送 Enter + Esc + 空白 + 滑鼠點,推過各前置畫面;每步截圖
i=0
for step in $(seq 1 14); do
  sleep 4
  xdotool key --clearmodifiers Return 2>/dev/null || true
  xdotool key --clearmodifiers Escape 2>/dev/null || true
  xdotool key --clearmodifiers space 2>/dev/null || true
  xdotool mousemove 320 240 click 1 2>/dev/null || true
  i=$((i+1))
  import -window root /out/shots/menu_$(printf %02d $i).png 2>/dev/null || true
done
kill $SV 2>/dev/null || true
tail -6 /tmp/sv.log 2>/dev/null | grep -vi alsa || true
