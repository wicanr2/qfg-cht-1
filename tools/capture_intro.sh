set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 70 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/sv.log &
SV=$!
sleep 3; xdotool key Return; sleep 1; xdotool key Return   # 跳版權
# 片頭序列:每 2s 按 Return 推進 + 截圖
for s in $(seq 1 20); do sleep 2; import -window root /out/shots/in2_$(printf %02d $s).png 2>/dev/null||true; xdotool key Return 2>/dev/null||true; done
kill $SV 2>/dev/null || true
