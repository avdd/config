
CONFIG_HOME=$HOME/common

. $CONFIG_HOME/shell/util.sh
. $CONFIG_HOME/shell/environment.sh

if shell_is_interactive && test "$BASH"
then
    source_all \
        $CONFIG_HOME/shell/ansi.sh      \
        $CONFIG_HOME/shell/backupsync.sh\
        $CONFIG_HOME/shell/git.sh       \
        $CONFIG_HOME/shell/hooks.sh     \
        $CONFIG_HOME/shell/custom.sh    \
        $CONFIG_HOME/shell/commands.sh  \
        $CONFIG_HOME/shell/settings.sh
fi

_init_compat
_init_path
_init_dirs
_init_local
_init_private
_init_login

if shell_is_interactive && test "$BASH"
then
    _init_settings
    _init_term
    _init_features
    _init_history
    _init_ls_colors
    _init_grep_colors
    _init_commands
    _init_prompt
    PROMPT_COMMAND=__prompt_command
    trap __preexec_trap DEBUG
fi

