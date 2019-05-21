
_init_settings() {

    #set -o noclobber

    bind "set completion-ignore-case on"
    bind "set completion-map-case on"
    bind "set show-all-if-ambiguous on"

    shopt -s dirspell
    shopt -s cdspell
    shopt -s globasciiranges 2>/dev/null

    CLEAR_INCOMPLETE_LINE_ENABLED=
    COMMAND_TITLE_ENABLED=1
    HIGHLIGHT_INPUT=1
    PROMPT_PWD_FANCY=1
    PROMPT_COMMAND_ERROR=1
    GIT_PROMPT_ENABLED=1
    HG_PROMPT_ENABLED=1

    # colors & visuals
    PS1_LOGIN_COLOR_USERLOCAL=189.
    PS1_LOGIN_COLOR_USERLOCAL=153.
    PS1_LOGIN_COLOR_OTHERLOCAL=213.
    PS1_LOGIN_COLOR_ROOTLOCAL=208.
    PS1_LOGIN_COLOR_USERREMOTE=75.
    PS1_LOGIN_COLOR_OTHERREMOTE=198.
    PS1_LOGIN_COLOR_ROOTREMOTE=226.
    PS1_PWD_FANCY_COLOR1=183.240
    PS1_PWD_FANCY_COLOR2=171.238
    PS1_ERROR_COLOR=11.b.1
    PS1_PWD_FANCY_SEPARATOR=/
    PS1_INPUT_PROMPT='\$'
    CLEAR_NEWLINE_COLOR=226.b.124
    CLEAR_NEWLINE_SYMBOL=↲
    #CD_BANNER_COLOR=41.b.20

    export PS_FORMAT=pid,user,cmd
    export EDITOR=vim
    export VISUAL=vim
    export PAGER=less
    export MANPAGER=less
    export LESS='-iXMSR'
    export LESSHISTFILE=- # no ~/.lesshst poop
    export PSQL_EDITOR="vi -c 'setf sql'"
    export PSQL_HISTORY="$HISTPATH/psql_history"
    export NCFTPDIR=/dev/null
    export PYTHONDONTWRITEBYTECODE=1 # no .pyc poop
    # colors for man pages
    export LESS_TERMCAP_md=$'\e[38;5;178;1m' # bold
    export LESS_TERMCAP_us=$'\e[38;5;81;1m' # underline
    export LESS_TERMCAP_so=$'\e[31m' # standout (reverse)
    export LESS_TERMCAP_mb=$'\e[32m' # blink
    export LESS_TERMCAP_me=$'\e[0m' # stop bold, blink, underline
    export LESS_TERMCAP_ue=$'\e[0m' # stop underline
    export LESS_TERMCAP_se=$'\e[0m' # stop standout

    export NPM_CONFIG_PREFIX=$HOME/.local
    export NPM_CONFIG_CACHE=$HOME/.cache/npm
    export NODE_PATH=$HOME/.local/lib/node_modules

}

