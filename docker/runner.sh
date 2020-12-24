#!/usr/bin/env bash

trap "echo -e '\nCaught ^C from user - exiting now' ; exit 0" SIGINT

node_modules/.bin/mockoon start "$@"
sleep infinity & wait $!
