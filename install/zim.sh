#!/usr/bin/env bash

set -e

ZIM_HOME="${ZIM_HOME:-${HOME}/.zim}"

install() {
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
}

uninstall() {
    rm -rf "${ZIM_HOME}"
}

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
