#!/usr/bin/env bash

set -e

source ../lib/zim.sh

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: ZIM_HOME=... $0 [install|uninstall]"
        exit 1
        ;;
esac
