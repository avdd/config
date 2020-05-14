
# zsh-style hooks

PRIVATE_ENV=
MASTER_ACTIVE_FLAG=
PS1_BACKUP=

chpwd() {
    test "$GIT_PROMPT_ENABLED" &&
        _prompt_git_check
    test "$HG_PROMPT_ENABLED" &&
        _prompt_hg_check
    # not good when used in functions etc
    #_cd_banner
}

preexec() {
    test "$HIGHLIGHT_INPUT" &&
        _clear_terminal_color
    test "$COMMAND_TITLE_ENABLED" &&
        _set_command_title
    history -a
}

precmd() {
    COMMAND_ERROR=$?
    test "$CLEAR_INCOMPLETE_LINE_ENABLED" &&
        insert_newline
    _prompt_update_vars
}

_prompt_history_hook() {
    if [[ $PRIVATE_ENV && # master
        -r "$MASTER_ACTIVE_FLAG" && # active
        -d ~/log/_rsyncsync_conflicts ]]
    then
        BACKUP_SYNC_COMMAND=
        return 1
    fi

    history -a

    if [[ "$PRIVATE_ENV" &&
        ! "$BACKUP_SYNC_COMMAND" &&
        -r "$MASTER_ACTIVE_FLAG" ]]
    then
        BACKUP_SYNC_COMMAND=_auto_history_backup
    fi
    test "$BACKUP_SYNC_COMMAND" &&
        _backup_sync_hook
}

_sync_conflict_quick_resolve() {
    local dir=~/log/_rsyncsync_conflicts
    local base=${HISTFILE//$HOME\/log\//}
    local backup=($dir/*/$base)
    if (( ${#backup[@]} != 1 ))
    then
        echo 'not the usual conflict'; return 1
    fi

    # HISTFILE has reverted to an older version, and our
    # local, new file backed up to $backup
    # we ensure the incoming file has no new lines, then
    # put our original 

    # lines in HISTFILE not in backup
    local diff1=$(comm -13 $backup $HISTFILE)
    # lines in backup not in HISTFILE
    local diff2=$(comm -23 $backup $HISTFILE)

    if [ "$diff1" ]
    then
        echo 'non local changes'; return 1
    fi

    if [ "$diff2" ]
    then
        echo OK, restoring $HISTFILE
        mv $f $HISTFILE
    else
        echo 'no difference'
        rm -f "$f"
    fi

    find "$dir" -depth -type d -delete
}

_init_term() {
    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    shopt -s checkwinsize
    test "$COLORTERM" = gnome-terminal &&
        TERM=xterm-256color

    test "$TERM" = xterm-256color &&
        X_TERM_IS_256COLOR=t

    export TERM X_TERM_IS_256COLOR

    # assume xterm gives us nice things
    case "$TERM" in
        xterm*|linux) ;;
        *)
        COMMAND_TITLE_ENABLED=
        CLEAR_NEWLINE_COLOR=
        CLEAR_NEWLINE_SYMBOL=
        PROMPT_PWD_FANCY=
        PS1_ERROR_COLOR=
        LOGIN_ABBREV=$USER@$HOSTNAME
        PS1_INPUT_PROMPT='>'
        ;;
    esac

    #_init_terminfo
}

_init_terminfo() {
    has_command tput || return
    tput init
    local TERM_COLORS=$(tput colors)
}

_init_features() {
    command ls --group-directories-first >/dev/null 2>&1 &&
        LS_DIRECTORIES_FIRST=1

    has_command colordiff &&
        HAS_COLORDIFF=1

    # make less more friendly for non-text input files, see lesspipe(1)
    test -x /usr/bin/lesspipe &&
        eval "$(SHELL=/bin/sh lesspipe)"

}

_init_history() {
    # append to the history file, don't overwrite it
    shopt -s histappend
    # disable XON/XOFF: use ctrl-s to forward search
    stty -ixon

    HISTSIZE=
    HISTFILESIZE=
    HISTCONTROL=erasedups:ignoreboth
    # TODO: HISTIGNORE
    HISTIGNORE='&:[ ]*:ls:l:ll:reset:clear'
    HISTTIMEFORMAT='%F %T '
    if [[ -d $HISTPATH ]]
    then
      HISTFILE=$HISTPATH/bash_history
    else
      unset HISTFILE
    fi
    _backup_sync_init $RUNPATH
}

_set_command_title() {
    local line=$(HISTTIMEFORMAT= history 1)
    set_term_title "${line:7}"
}

_clear_terminal_color() {
    echo -en "$ESC_RESET$ESC_FILL" > `tty`
}

_init_bash_completion() {
    shopt -oq posix && return 0
    source_first \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion ||
        echo 'missing bash-completion' >&2
}

_init_prompt() {
    PS1_TITLE=
    PS1_LOGIN=
    PS1_HIGHLIGHT=

    local prefix=
    test "$LOGIN_ABBREV" && prefix=$LOGIN_ABBREV:
    case "$TERM" in
        vt100|xterm*|rxvt*|screen*|cygwin)
        PS1_TITLE="$ESC_TITLE$prefix\w$ESC_BEL"
        ;;
    esac

    if test "$LOGIN_ABBREV"
    then
        local color s
        _coloropt ps1_login_color_$LOGIN_TYPE color
        bold=$ESC_BOLD
        _setesc PS1_LOGIN "\[$color$bold\]$LOGIN_ABBREV\[$ESC_RESET\]"
    fi

    _setesc PS1_CLEAR "$ESC_RESET"
    if test "$HIGHLIGHT_INPUT"
    then
        #_coloropt ps1_login_color_$LOGIN_TYPE color
        PS2="$ESC_RESET> $ESC_RV"
        _setesc PS1_HIGHLIGHT "$ESC_RV"
    fi

    # readable layout for PS1 !
    local elems=(
        '\[$PS1_CLEAR\]'
        "\\[$PS1_TITLE\\]"
        '$PS1_ERROR'
        '$PS1_PWD'
        '\n'
        '\[$PS1_CLEAR\]'
        "$PS1_LOGIN"
        '$PS1_BACKUP'
        '\$ '
        '\[$PS1_HIGHLIGHT\]'
    )
    concat_string PS1 "${elems[@]}"

}

_prompt_update_vars() {
    test "$PROMPT_COMMAND_ERROR" &&
        _ps1_command_error
    _ps1_pwd
    #_ps1_backup_status
}

_setesc() {
    eval "$1=\$'$2'"
}

_ps1_command_error() {
    local e=$COMMAND_ERROR
    local render= color
    if (( $e ))
    then
        [ "$PS1_ERROR_COLOR" ] &&
            _coloropt PS1_ERROR_COLOR color ||
            color='\e[1;33;41m'
        render="$color $e $ESC_RESET\n"
    fi
    _setesc PS1_ERROR "$render"

}

_ps1_pwd() {
    PS1_PWD=''
    PS1_PWD_VTE=''
    test "$PROMPT_PWD_FANCY" &&
        _ps1_pwd_fancy ||
        PS1_PWD=${PWD/#$HOME\//'~'/}
    return 0
    # forward compat for newer vte
    case "$TERM" in
        xterm*|vte*) _ps1_vte_pwd ;;
    esac
}

_ps1_pwd_fancy() {
    local c1 c2
    _coloropt ps1_pwd_fancy_color1 c1
    _coloropt ps1_pwd_fancy_color2 c2

    local pwd=${PWD/#$HOME\//'~'/}
    local i=0 pad='' dir= render= color=
    local sep=/

    pwd=${pwd#/}
    while [[ "$pwd" = */* ]]
    do
        dir=${pwd%%/*}
        [ "$dir" = '~' ] && sep=''
        ((i++%2)) && color=$c2 || color=$c1
        render+="$color$pad$sep$dir" 
        pwd=${pwd#*/}
        pad=''
        sep=/
    done
    dir=${pwd%%/*}
    ((i++%2)) && color=$c2 || color=$c1
    render+="$color$pad$sep$dir" 
    render+="$c2$ESC_FILL$ESC_RESET"
    _setesc PS1_PWD "$render"
}

_ps1_backup_status() {
    local grn yel red n color char locked s
    # ◯ ○ ◯ x o × x X × ⨯ ✖ ✗ ✘ ◼
    #local maru=o batsu=x other=+
    _coloresc red 196.b.
    _coloresc grn 82.b.
    _coloresc yel1 220.
    _coloresc yel2 220.b.
    if test "$BACKUP_SYNC_COMMAND"
    then
        # backup sync enabled, get status
        _backup_sync_status char
        test $? -ne 0 && locked=1
        color=$yel1
        test $char = 0 && color=$grn char=o
        test "$locked" && color=$red
    elif [[ -r "$MASTER_ACTIVE_FLAG" ]]
    then
        # backup disabled by conflict
        char=x color=$red
    elif [[ -r "$PRIVATE_ENV" ]]
    then
        # master unlocked
        char='=' color=$yel2
    elif [[ "$PRIVATE_ENV" ]]
    then
        # master locked
        char=X color=$yel2
    else
        # slave
        char='~' color=$yel2
    fi
    s="$color$char$ESC_RESET"
    _setesc PS1_BACKUP "$s"
}

_urlencode() {
    local save_lc_all=$LC_ALL
    LC_ALL=C
    local name=$1 str=$2 safe= out= pf=
    while [ -n "$str" ]
    do
        safe="${str%%[!a-zA-Z0-9/:_\.\-\!\'\(\)~]*}"
        out+="$safe"
        str="${str#"$safe"}"
        if [ -n "$str" ]; then
            printf -v pf "%%%02X" "'$str"
            out+=$pf
            str="${str#?}"
        fi
    done
    [[ "$name" && "$out" ]] && eval "$name=\$out"
    LC_ALL=$save_lc_all
}

_ps1_vte_pwd() {
    local vte_pwd
    _urlencode vte_pwd "$PWD"
    local esc="\e]7;file://%s%s\a"
    printf -v PS1_PWD_VTE "$esc" "${HOSTNAME:-}" "$vte_pwd"
}

__unused__ps1_backup_status_unicode() {
    return

    # show a nice unicode bar

    local chars=( ' ' _ ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ )
    local red=$'\e[31m'
    local yel=$'\e[33m'
    local grn=$'\e[32m'
    local clr=$'\e[0m'

    local n=${#chars[@]}
    local d=$(($BACKUP_SYNC_DELAY - 2))
    
    local i=$(( ($c * ($n-1)) / ($d) ))
    local ch=${chars[$i]}

    if test $c -eq $(($BACKUP_SYNC_DELAY - 1))
    then ch="$red$ch$clr"
    elif test $c -eq $(($BACKUP_SYNC_DELAY - 2))
    then ch="$yel$ch$clr"
    fi

    echo "$ch"
}

_prompt_git_check() {
    return 0
    if test -d .git
    then
        GIT_DIR=$PWD/.git
    else
        unset GIT_DIR
    fi
}

_prompt_hg_check() {
    return 0
    if test -d .hg
    then
        HG_DIR=$PWD
    else
        unset HG_DIR
    fi
}

_init_ls_colors() {
    # ls color for OSX
    export CLICOLOR=1
    local dircolors=$CONFIG_HOME/dircolors
    if [ "$TERM" != "dumb" ] &&
            has_command dircolors &&
            command ls --color >/dev/null 2>&1
    then
        test -r "$dircolors" || dircolors=
        eval "$(dircolors -b $dircolors)"
    fi
}

_init_grep_colors() {
    local colors=(
        #:sl='48;5;90'      # matching lines
        :cx=                # context lines
        :mt='48;5;229;38;5;0;1'       # any match -v or normal
        #:ms='1;31'       # match in non -v mode
        #:mc='1;31'       # match in -v mode (context line)
        :fn='38;5;134'      # filename prefix
        :ln=32           # line number prefix
        :bn=32           # byte offset
        :se=36           # separator
        # off:
        #rv             # reverse sl and cx when using -v switch
        #ne             # disable \E[K erase line
    )
    concat_string GREP_COLORS "${colors[@]}"
    export GREP_COLORS
}

_cd_banner() {
    #return
    local color limit files
    _coloropt cd_banner_color color
    limit=${CD_BANNER_LS_LIMIT:-50}
    echo
    #echo -e "$color$PWD $ESC_FILL$ESC_RESET"
    #echo
    files=(*)
    test ${#files[@]} -lt $limit &&
        _ls_wrapper -lh ||
        echo ${#files[@]} entries
    echo
}

_coloropt() {
    local opt=$1 var=$2 val
    test "$var" || var=$opt
    eval "val=\$${opt^^}"
    _coloresc ${var,,} $val
}

_render_ps1() {
    eval "echo -en \"$PS1\"" | tr -d '\001-\002'
}

_test_prompt() {
    restore_user=$USER
    restore_hostname=$HOSTNAME
    tests=(
        avdd@local
        other@local
        root@local
        avdd@remote
        other@remote
        root@remote
    )
    COMMAND_ERROR=2
    for pair in ${tests[@]}
    do
        USER=${pair%%@*}
        HOSTNAME=${pair##*@}
        test $HOSTNAME = local || SSH_CLIENT=1
        _init_login
        _init_prompt
        _prompt_update_vars
        _render_ps1
        cmd="example text for command entry\n$LOGIN_TYPE"
        echo -e $cmd
        echo -e "$ESC_RESET"
    done
    USER=$restore_user
    HOSTNAME=$restore_hostname
    read -p 'exiting...'; exit
}
