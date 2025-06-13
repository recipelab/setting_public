#!/bin/bash

while true; do
    if [[ "$(fgconsole)" == "1" ]] && systemctl is-active --quiet display-manager
    then
        systemctl restart display-manager
        chvt 7

        exit 0
    fi
    sleep 0.1
done