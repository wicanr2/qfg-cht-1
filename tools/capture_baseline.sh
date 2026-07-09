set -e
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
# 偵測並加入遊戲
./scummvm --path=/game --add --recursive >/tmp/add.log 2>&1 || true
TARGET=$(./scummvm --list-targets 2>/dev/null | awk 'NR>2{print $1; exit}')
echo "TARGET=$TARGET"
timeout 34 ./scummvm --path=/game --auto-detect 2>/tmp/sv.log &
SV=$!
for t in 04 08 12 16 20 26 32; do
  sleep 4
  import -window root /out/shots/base_${t}s.png 2>/dev/null || \
    xwd -root -silent 2>/dev/null | convert xwd:- /out/shots/base_${t}s.png 2>/dev/null || true
done
kill $SV 2>/dev/null || true
echo "=== scummvm stderr tail ==="; tail -20 /tmp/sv.log
