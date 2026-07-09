set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 95 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
SV=$!
WID=""
for step in $(seq 1 18); do
  sleep 4.5
  xdotool key --clearmodifiers Escape 2>/dev/null || true
  xdotool key --clearmodifiers Return 2>/dev/null || true
  xdotool mousemove 320 240 click 1 2>/dev/null || true
  import -window root /out/shots/nav_$(printf %02d $step).png 2>/dev/null || true
done
kill $SV 2>/dev/null || true
