# shellcheck source=../state/env.sh
source ../state/env.sh

NAME="${NAME:-system}"

PREFIX="${__OPT_ROOT}/${NAME}"

# shellcheck disable=SC2312
read -r __OSTYPE __ARCH <<< "$(uname -sm)"

mamba_env_install() {
    case "${__OSTYPE}-${__ARCH}" in
        Darwin-arm64) CONDA_UNAME=osx-arm64 ;;
        Darwin-x86_64) CONDA_UNAME=osx-64 ;;
        Linux-x86_64) CONDA_UNAME=linux-64 ;;
        Linux-aarch64) CONDA_UNAME=linux-aarch64 ;;
        Linux-ppc64le) CONDA_UNAME=linux-ppc64le ;;
        *) exit 1 ;;
    esac
    file="conda/${NAME}_${CONDA_UNAME}.yml"

    if [[ -d ${PREFIX} ]]; then
        mamba env update -f "${file}" -p "${PREFIX}" -y --prune
    else
        mamba env create -f "${file}" -p "${PREFIX}" -y
    fi
}

mamba_env_uninstall() {
    rm -rf "${PREFIX}"
}
