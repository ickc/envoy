print_double_line() {
    if [[ -n ${COLUMNS} ]]; then
        eval printf %.0s= '{1..'"${COLUMNS}"\}
    else
        echo '================================================================================'
    fi
}

print_line() {
    eval printf %.0s- '{1..'"${COLUMNS:-80}"\}
    if [[ -n ${COLUMNS} ]]; then
        eval printf %.0s- '{1..'"${COLUMNS}"\}
    else
        echo '--------------------------------------------------------------------------------'
    fi
}
