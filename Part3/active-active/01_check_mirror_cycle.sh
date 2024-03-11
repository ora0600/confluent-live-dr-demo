#!/bin/bash

pwd > basedir
export BASEDIR=$(cat basedir)

# Start consumer check of mirror cylce
echo ""
echo "Start Clients for consumer check...."
open -a iterm
sleep 10
osascript ./00_terminal.scpt $BASEDIR