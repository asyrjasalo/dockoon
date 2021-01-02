#!/bin/sh

trap "echo -e '\nCaught ^C, exiting gracefully...' ;
node_modules/.bin/mockoon stop all ; exit 0" INT TERM
# or use https://docs.docker.com/engine/reference/run/#specify-an-init-process

node_modules/.bin/mockoon "$@"

[ "$1" = "start" ] && tail -f ~/.mockoon-cli/logs/*.log | while read -r
do
    echo "$(date +%H:%M:%S) $REPLY"
done
