
# when leaving the console clear the screen to increase privacy

test "$SHLVL" = 1 &&
    shell_is_interactive &&
    test -x /usr/bin/clear_console &&
    /usr/bin/clear_console -q ||
    true

