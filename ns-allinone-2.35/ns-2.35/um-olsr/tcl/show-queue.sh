#!/bin/sh

xgraph queue-size.tr -geometry 800x400 -t "Queue size(pkts)" -x "secs" -y "pkts" -fg darkblue&
xgraph queue-band.tr -geometry 800x400 -t "Bandwidth(Kbps)" -x "secs" -y "Kbps" -fg white &
xgraph queue-drop.tr -geometry 800x400 -t "Drop rate(pkts/sec)" -x "secs" -y "pkts" -fg red &
