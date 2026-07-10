set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 60 ./scummvm --path=/game --auto-detect --language=tw 2>/out/gfx.log &
SV=$!
sleep 3; xdotool key Return; sleep 1; xdotool key Return   # 跳版權→到選單
sleep 3; import -window root /out/shots/gfx_menu.png        # 選單截圖(對應 log)
xdotool key Return                                          # 選 Introduction
for s in $(seq 1 18); do sleep 2; xdotool key Return 2>/dev/null||true; done
kill $SV 2>/dev/null || true
