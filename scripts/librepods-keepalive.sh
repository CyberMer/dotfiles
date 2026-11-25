#!/bin/sh
# Keep librepods (AirPods helper) running: restart it when it crashes, not when you quit it yourself.
for p in $(pgrep -f "^/bin/sh $0"); do [ "$p" != "$$" ] && exit 0; done   # only one copy
while :; do
    librepods --hide
    code=$?
    [ $code -le 128 ] && exit 0      # normal quit: stop
    sleep 3                          # crash (killed by a signal): start it again
done
