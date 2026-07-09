set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
PREFIX="${PREFIX:-base}"
EXTRA="${EXTRA:-}"
# 加遊戲並自動啟動;--start-movie 無;用 --auto-detect 直接跑
timeout 40 ./scummvm --path=/game --auto-detect $EXTRA 2>/tmp/sv.log &
SV=$!
for t in 05 09 13 18 24 30 36; do
  sleep 5
  import -window root /out/shots/${PREFIX}_${t}s.png 2>/dev/null || true
done
kill $SV 2>/dev/null || true
echo "=== stderr tail ==="; tail -15 /tmp/sv.log
