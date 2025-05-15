ZIM_HOME="${ZIM_HOME:-${HOME}/.zim}"

install() {
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
}

uninstall() {
    rm -rf "${ZIM_HOME}"
}
