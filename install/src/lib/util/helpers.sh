print_double_line() {
    eval printf %.0s= '{1..'"${COLUMNS:-80}"\}
}

print_line() {
    eval printf %.0s- '{1..'"${COLUMNS:-80}"\}
}
