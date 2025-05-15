#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/sman.sh
source ../lib/sman.sh

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: __OPT_ROOT=... $0 [install|uninstall]"
        exit 1
        ;;
esac
