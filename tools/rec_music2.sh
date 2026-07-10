export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
export SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=/out/music/qfg_cap.raw
# 不設 DISKAUDIODELAY=0 → 近即時
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 70 ./scummvm --path=/game --auto-detect --music-driver=adlib --music-volume=255 2>/tmp/m.log &
# 前 ~10s 送 Enter/space 推過 logo/版權 → 進 credits(有音樂)
for i in 1 2 3 4 5; do sleep 2; xdotool key Return 2>/dev/null; xdotool key space 2>/dev/null; done
# credits 播音樂,錄 ~40s wall
sleep 40
pkill scummvm 2>/dev/null; sleep 1
echo "=== 音樂 driver log ==="; grep -iE "adlib|midi|audio|sound|driver" /tmp/m.log | head -4
ls -la /out/music/qfg_cap.raw
