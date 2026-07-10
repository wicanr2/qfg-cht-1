export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
export SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=/out/music/qfg_cap.raw SDL_DISKAUDIODELAY=0
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
# 開 AdLib 音樂、音量拉滿;跑 intro 約 25s wall(disk 全速會灌出大量音訊)
timeout 25 ./scummvm --path=/game --auto-detect --music-driver=adlib --music-volume=255 2>/tmp/m.log &
sleep 24; pkill scummvm 2>/dev/null; sleep 1
ls -la /out/music/qfg_cap.raw 2>/dev/null
