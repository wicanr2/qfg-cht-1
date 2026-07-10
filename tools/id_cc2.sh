export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SCI_LOG_GFX=1
Xvfb :99 -screen 0 640x480x24 >/tmp/x.log 2>&1 & sleep 2
cd /src
timeout 160 ./scummvm --path=/game --auto-detect --language=tw 2>/tmp/g.log &
for s in $(seq 1 17); do sleep 4.5; xdotool key Escape 2>/dev/null; xdotool mousemove 320 240 click 1 2>/dev/null; done
import -window root /out/shots/cc2_classselect.png 2>/dev/null
echo "=====CLASSSEL=====" >> /tmp/g.log
# 精準點左雕像(fighter)身體,不再亂點
sleep 1; xdotool mousemove 130 200 click 1 2>/dev/null
sleep 5; import -window root /out/shots/cc2_after1.png 2>/dev/null
echo "=====AFTER1=====" >> /tmp/g.log
xdotool key Return 2>/dev/null
sleep 5; import -window root /out/shots/cc2_after2.png 2>/dev/null
sleep 4; import -window root /out/shots/cc2_after3.png 2>/dev/null
pkill scummvm 2>/dev/null; sleep 1
echo "=== 職業選擇畫面(CLASSSEL 前最後)繪的 view ==="
awk '/SCI_LOG_GFX view/{v=$0} /=====CLASSSEL=====/{exit} {if(/SCI_LOG_GFX view/)last=last"\n"$0} END{}' /tmp/g.log >/dev/null
grep "SCI_LOG_GFX view" /tmp/g.log | sed 's/.*SCI_LOG_GFX //' | tail -25 | sort | uniq -c | sort -rn
echo "=== AFTER1 之後(可能角色創建)繪的 view/pic ==="
awk '/=====AFTER1=====/{m=1} m && (/SCI_LOG_GFX view/||/drawPicture/)' /tmp/g.log | sed 's/.*SCI_LOG_GFX //;s/.*WARNING: //' | sort -u | head -30
