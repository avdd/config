
CONFIG_HOME=$HOME/current/config

. $CONFIG_HOME/shell/util.sh
. $CONFIG_HOME/shell/environment.sh

if shell_is_interactive && test "$BASH"
then
    source_all \
        $CONFIG_HOME/shell/modules/*.sh \
        $CONFIG_HOME/shell/custom.sh    \
        $CONFIG_HOME/shell/commands.sh  \
        $CONFIG_HOME/shell/settings.sh  \
        $CONFIG_HOME/shell/greeting.sh
fi

_init_compat
_init_path
_init_dirs
_init_local
_init_private
_init_login

if shell_is_interactive && test "$BASH"
then
    __install_hooks
    _init_term
    _init_features
    _init_history
    _init_completion
    _init_ls_colors
    _init_grep_colors
    _init_commands
    _init_prompt

    cd .
    test "$SUDO_USER" || _greeting

    #_test_prompt

fi

