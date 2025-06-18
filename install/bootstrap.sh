#!/usr/bin/env bash

set -eo pipefail

__MAMBA_ENV_DOWNLOAD=1

# git 2.3.0 or later is required
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

github_clone_git() {
    user="${1}"
    repo="${2}"
    git clone "git@github.com:${user}/${repo}.git"
}

github_clone_https() {
    user="${1}"
    repo="${2}"
    git clone "https://github.com/${user}/${repo}.git"
}

github_download_file_to() {
    user="${1}"
    repo="${2}"
    branch="${3}"
    file="${4}"
    dest="${5}"
    mkdir -p "${dest%/*}"
    curl -L "https://raw.githubusercontent.com/${user}/${repo}/refs/heads/${branch}/${file}" -o "${dest}"
}

download_dotfiles() {
    echo 'Temporarily downloading dotfiles'
    github_download_file_to ickc dotfiles master config/zsh/.zshenv ~/.zshenv
    github_download_file_to ickc dotfiles master config/zsh/.zshrc ~/.zshrc
}

download_dotfiles
# shellcheck disable=SC1090
. ~/.zshenv || true
# shellcheck disable=SC1090
. ~/.zshrc || true
# this must be after sourcing dotfiles
__OPT_ROOT="${__OPT_ROOT:-"${HOME}/.local"}"
MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-"${HOME}/.miniforge3"}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"${HOME}/.config"}"
ZDOTDIR="${ZDOTDIR:-"${XDG_CONFIG_HOME}/zsh"}"
print_double_line() {
    echo '================================================================================'
}

print_line() {
    echo '--------------------------------------------------------------------------------'
}
BSOS_SSH_COMMENT="${USER}@${HOSTNAME}"

ssh_keygen_and_login() {
    # determine ssh algorithm to use
    # shellcheck disable=SC2312
    if ssh -Q key | grep -q "ssh-ed25519"; then
        SSH_ALGO=ed25519
    elif ssh -Q key | grep -q "ssh-rsa"; then
        SSH_ALGO=rsa
    else
        echo "No supported ssh algorithm found, abort..."
        return
    fi

    if [[ -f "${HOME}/.ssh/id_${SSH_ALGO}.pub" ]]; then
        echo "SSH key already exists, assuming ssh-agent is setup to pull from GitHub and skip generating ssh key."
    else
        echo "Generating ssh key for ${BSOS_SSH_COMMENT}"
        mkdir -p "${HOME}/.ssh"
        ssh-keygen -t "${SSH_ALGO}" -C "${BSOS_SSH_COMMENT}" -f "${HOME}/.ssh/id_${SSH_ALGO}"
        # shellcheck disable=SC1090,SC2312
        . <(ssh-agent -s)
        ssh-add "${HOME}/.ssh/id_${SSH_ALGO}"

        # authenticate with GitHub
        gh auth login --git-protocol ssh --web
    fi
}

ssh_dir_install() {
    cd ~
    github_clone_git ickc ssh-dir
    cd ssh-dir
    mv ~/.ssh/id_ed25519 ~/ssh-dir
    mv ~/.ssh/id_ed25519.pub ~/ssh-dir
    rm -rf ~/.ssh
    mv ~/ssh-dir ~/.ssh
}
BINDIR="${__OPT_ROOT}/bin"

# shellcheck disable=SC2312
read -r __OSTYPE __ARCH <<< "$(uname -sm)"

code_install() {
    case "${__OSTYPE}-${__ARCH}" in
        "Linux-x86_64")
            url="https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64"
            ;;
        "Linux-armv7l")
            url="https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-armhf"
            ;;
        "Linux-aarch64")
            url="https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64"
            ;;
        "Darwin-x86_64")
            url="https://code.visualstudio.com/sha/download?build=stable&os=cli-darwin-x64"
            ;;
        "Darwin-arm64")
            url="https://code.visualstudio.com/sha/download?build=stable&os=cli-darwin-arm64"
            ;;
        *)
            echo "Unsupported OS or architecture"
            exit 1
            ;;
    esac

    case "${__OSTYPE}" in
        Darwin)
            if command -v curl > /dev/null; then
                curl -L "${url}" -o vscode_cli.zip
            elif command -v wget > /dev/null; then
                wget "${url}" -O vscode_cli.zip
            fi
            unzip vscode_cli.zip
            rm vscode_cli.zip
            ;;
        Linux)
            if command -v curl > /dev/null; then
                # shellcheck disable=SC2312
                curl -fL "${url}" | tar -xz
            elif command -v wget > /dev/null; then
                # shellcheck disable=SC2312
                wget -O - "${url}" | tar -xz
            fi
            ;;
        *) ;;
    esac

    mkdir -p "${BINDIR}"
    mv code "${BINDIR}"
}

code_uninstall() {
    rm -rf "${BINDIR}/code"
}
# https://unix.stackexchange.com/a/84980/192799
DOWNLOADDIR="$(mktemp -d 2> /dev/null || mktemp -d -t 'miniforge3')"

# shellcheck disable=SC2312
read -r __OSTYPE __ARCH <<< "$(uname -sm)"

mamba_install() {
    case "${__OSTYPE}-${__ARCH}" in
        Darwin-arm64) ;;
        Darwin-x86_64) ;;
        Linux-x86_64) ;;
        Linux-aarch64) ;;
        Linux-ppc64le) ;;
        *) exit 1 ;;
    esac
    # https://github.com/conda-forge/miniforge
    downloadUrl="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${__OSTYPE}-${__ARCH}.sh"

    print_double_line
    echo Downloading to temp dir "${DOWNLOADDIR}"
    cd "${DOWNLOADDIR}" || exit 1
    curl -L "${downloadUrl}" -o Miniforge3.sh
    chmod +x Miniforge3.sh

    print_double_line
    if [[ -f "${MAMBA_ROOT_PREFIX}/etc/profile.d/conda.sh" ]]; then
        echo Updating mamba...
        ./Miniforge3.sh -ubsp "${MAMBA_ROOT_PREFIX}"
    else
        echo Installing mamba...
        ./Miniforge3.sh -fbsp "${MAMBA_ROOT_PREFIX}"
    fi

    print_line
    echo Removing temp dir "${DOWNLOADDIR}"
    cd - || exit 1
    rm -rf "${DOWNLOADDIR}"
}

mamba_uninstall() {
    rm -rf "${MAMBA_ROOT_PREFIX}"
}
NAME="${NAME:-system}"

PREFIX="${__OPT_ROOT}/${NAME}"

# shellcheck disable=SC2312
read -r __OSTYPE __ARCH <<< "$(uname -sm)"

get_conda_env_file() {
    case "${__OSTYPE}-${__ARCH}" in
        Darwin-arm64) CONDA_UNAME=osx-arm64 ;;
        Darwin-x86_64) CONDA_UNAME=osx-64 ;;
        Linux-x86_64) CONDA_UNAME=linux-64 ;;
        Linux-aarch64) CONDA_UNAME=linux-aarch64 ;;
        Linux-ppc64le) CONDA_UNAME=linux-ppc64le ;;
        *) exit 1 ;;
    esac
    local filename
    filename="${NAME}_${CONDA_UNAME}.yml"
    if [[ -z ${__MAMBA_ENV_DOWNLOAD+x} ]]; then
        # use local file
        # shellcheck disable=SC2312
        __MAMBA_ENV_FILE="conda/${filename}"
    else
        __MAMBA_ENV_FILE="${HOME}/${filename}"
        github_download_file_to ickc envoy main "conda/${filename}" "${__MAMBA_ENV_FILE}"
    fi
}

mamba_env_install() {
    get_conda_env_file
    if [[ -d ${PREFIX} ]]; then
        "${MAMBA_ROOT_PREFIX}/bin/mamba" env update -f "${__MAMBA_ENV_FILE}" -p "${PREFIX}" -y --prune
    else
        "${MAMBA_ROOT_PREFIX}/bin/mamba" env create -f "${__MAMBA_ENV_FILE}" -p "${PREFIX}" -y
    fi
    if [[ -n ${__MAMBA_ENV_DOWNLOAD+x} ]]; then
        rm -f "${__MAMBA_ENV_FILE}"
    fi
}

mamba_env_uninstall() {
    rm -rf "${PREFIX}"
}
VERSION=1.0.4
BINDIR="${__OPT_ROOT}/bin"

# shellcheck disable=SC2312
read -r __OSTYPE __ARCH <<< "$(uname -sm)"

sman_install_bin() {
    case "${__OSTYPE}-${__ARCH}" in
        Darwin-arm64) GO_UNAME=darwin-arm64 ;;
        Darwin-x86_64) GO_UNAME=darwin-amd64 ;;
        Linux-x86_64) GO_UNAME=linux-amd64 ;;
        Linux-aarch64) GO_UNAME=linux-arm64 ;;
        Linux-ppc64le) GO_UNAME=linux-ppc64le ;;
        FreeBSD-amd64) GO_UNAME=freebsd-amd64 ;;
        *) exit 1 ;;
    esac
    filename="sman-${GO_UNAME}-v${VERSION}"
    url="https://github.com/ickc/sman/releases/download/v${VERSION}/${filename}.tgz"

    if command -v curl > /dev/null; then
        # shellcheck disable=SC2312
        curl -fL "${url}" | tar -xz
    elif command -v wget > /dev/null; then
        # shellcheck disable=SC2312
        wget -O - "${url}" | tar -xz
    fi
    mkdir -p "${BINDIR}"
    mv "${filename}" "${BINDIR}/sman"
}

sman_install_rc() {
    mkdir -p "${ZDOTDIR}/functions"
    github_download_file_to ickc sman master sman.rc "${ZDOTDIR}/functions/sman.rc"
}

sman_install_snippets() {
    if [[ -d ~/git/source/sman-snippets ]]; then
        cd ~/git/source/sman-snippets
        git pull
    else
        mkdir -p ~/git/source
        cd ~/git/source
        github_clone_git ickc sman-snippets
    fi
}

sman_install() {
    sman_install_bin
    sman_install_rc
    sman_install_snippets
}

sman_uninstall() {
    rm -f "${BINDIR}/sman" "${ZDOTDIR}/functions/sman.rc"
    rm -rf ~/git/source/sman-snippets
}
ZIM_HOME="${ZIM_HOME:-${HOME}/.zim}"

zim_install() {
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
}

zim_uninstall() {
    rm -rf "${ZIM_HOME}"
}

main() {

    print_double_line
    echo 'Installing VSCode CLI'
    code_install
    print_double_line
    echo "Installing mamba to ${MAMBA_ROOT_PREFIX}"
    mamba_install
    print_double_line
    echo 'Installing system environment via mamba'
    mamba_env_install
    print_double_line
    echo 'Installing zim'
    zim_install

    # shellcheck disable=SC1090
    . ~/.zshrc || true

    print_double_line
    echo 'Generating SSH key and login to GitHub'
    ssh_keygen_and_login

    # this clone sman-snippets so it must be after ssh_keygen_and_login
    print_double_line
    echo 'Installing sman'
    sman_install

    mkdir -p ~/git/source
    cd ~/git/source
    if [[ ! -d ~/git/source/envoy ]]; then
        print_double_line
        echo 'Cloning envoy'
        github_clone_git ickc envoy
    fi
    envoy/completion/generate.sh
    if [[ ! -d ~/git/source/dotfiles ]]; then
        print_double_line
        echo 'Cloning dotfiles'
        github_clone_git ickc dotfiles
    fi
    cd dotfiles
    print_double_line
    echo 'Installing dotfiles'
    # this will overwrite ~/.zshenv
    make all
    rm -f ~/.zshrc

    print_double_line
    echo 'Installing to ~/.ssh'
    ssh_dir_install
}

main
