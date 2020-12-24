#!/usr/bin/env bash

trap "echo -e '\nCaught ^C from user - exiting now' ; exit 0" SIGINT

node_modules/.bin/mockoon "$@"
[ "$1" = "start" ] && (sleep infinity & wait $!)
