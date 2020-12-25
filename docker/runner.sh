#!/bin/sh

node_modules/.bin/mockoon "$@"

[ "$1" = "start" ] && tail -f ~/.mockoon-cli/logs/*.log | while read -r
do
    echo "$(date +%H:%M:%S) $REPLY"
done
