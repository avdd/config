
# when leaving the console clear the screen to increase privacy

_clear_console() {
    test -x /usr/bin/clear_console &&
        /usr/bin/clear_console -q
    printf '\e]0;\a'
}

test "$SHLVL" = 1 &&
    shell_is_interactive &&
    _clear_console ||
    true

