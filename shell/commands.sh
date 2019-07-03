
# bash interactive commands & aliases

shopt -s extglob

_init_commands() {
    # shopt -s autocd # cd when using dir as command

    alias e=vim
    alias e='vim --servername GVIM --remote'

    alias -- --='cd ~-'
    alias ls="_ls_wrapper -lh"
    alias lc='_ls_wrapper -CA'
    alias mv='mv -i'
    alias rm='rm -i'
    alias cp='cp -i'
    alias df='df -h -x tmpfs -x devtmpfs -x squashfs'
    alias c=_cd_ls
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff=_diff_wrapper
    alias pwsafe=_pwsafe_wrapper
    alias pwsafe-echo=_pwsafe_echo
    alias pwsafe-copy=_pwsafe_copy
    alias ncp=_netcopy
    alias po=_toggle_prompt
    alias sudo=_sudo_wrapper
    alias unlock=_unlock_private_keys
    alias psql=_psql_wrapper
    alias backup=_encfs_backup
    alias s=_backup_sync_control
    alias b=_backup_current_trigger
    alias word=_word
    alias gist='git status'
    alias gidi='git diff'
    alias timestamp=_timestamp
    alias tmpmount=_tmpmount
    alias cl='clear -x'
    alias mksshrsa=_mk_ssh_rsa
    alias mksshed=_mk_ssh_ed
    alias mvln=_mvln
}

_mvln() {
    test "$1" && test "$2" || {
        echo usage: mvln SRC DST
        return 1
    }
    test -e "$2" && {
        echo "$2 exists!"
        return 2
    }
    mv -Tv "$1" "$2" && ln -sv "$2" "$1"
}

_mk_ssh_rsa() {
    test "$1" || {
        echo ID required
        return 1
    }
    _mksshkey $1 -t rsa -b 4096
}

_mk_ssh_ed() {
    test "$1" || {
        echo ID required
        return 1
    }
    _mksshkey $1 -t ed25519
}

_mksshkey() {
    local id=$1
    test "$KEYSTORE" || {
        echo KEYSTORE unset
        return 1
    }
    shift
    local comment="$USER"-"$id"@$HOSTNAME
    local file="$HOSTNAME"_"${id//-/_}"
    ssh-keygen -C "$comment" -f "$KEYSTORE/$file" "$@"
}

_tmpmount() {
    sudo mount -t tmpfs none "$1"
    sudo chown $USER:$USER "$1"
}

_timestamp() {
    date "$@" '+%Y%m%d_%H%M%S'
}

_word() {
    grep -v '^$' ~/static/words.txt  | shuf -n 1
}

_encfs_backup() {
    local env=$HOME/current/config/shell/init.sh
    local script=$HOME/current/work/self/rsyncsync/rsyncsync-encfs.sh
    BASH_ENV=$env $script "$@"
}

_backup_current_trigger() {
    _encfs_backup config-repeat CURRENT
}

_auto_history_backup() {
    DEBUG=1 \
    RSYNCSYNC_MERGE_DISCARD_OLD=1 \
    RSYNCSYNC_WRITE_STATUS=~/log/.rsyncsync/status \
        _encfs_backup config-targets LOG \
        &>> /tmp/backupsync.log
}

prune_empty_dirs() {
    test -d "$1" || return 1
    find "$1" -depth -type d -delete 2>/dev/null || true
}

truncate_file() {
    # for bash history, 'keep' must be even!
    local keep file lines suf
    keep=$1
    file=$2
    new=$3
    ((keep > 1)) || { echo 'require keep arg > 1'; return 1; }
    [ -r "$file" ] || { echo require file arg; return 1; }
    [ "$new" ] || { echo require new file arg; return 1; }

    lines=$(wc -l "$file" | cut -d' ' -f1)
    ((lines > keep))                    &&
        ((archive=lines - keep))        &&
        head -$archive "$file" > $new &&
        sed -i "1,$archive d" "$file"
}

_psql_wrapper() {
    if [ "$COMP_LINE" ]
    then
        command psql "$@";
        return $?
    fi
    test "$PSQL_HISTORY" || {
        echo PSQL_HISTORY not set
        return 1
    }
    # work around psql/readline bugs:
    # 1. no concurrent processes (clobbers history)
    local pidfile=$RUNPATH/psql.pid
    if test -e "$pidfile"
    then
        local shellpid=$(cat $pidfile)
        local pids
        if pids=$(pidof psql)
        then
            echo running:
            ps $shellpid $pids
        else
            echo locked by $pidfile
            echo shellpid=$shellpid self=$$
            ps $shellpid $$
        fi
        return 1
    fi

    # 2. touch the history file to avoid spurious error
    test -r $PSQL_HISTORY ||
        touch $PSQL_HISTORY ||
        return 1

    echo $$ >| $pidfile
    command psql -v HISTFILE=$PSQL_HISTORY "$@"
    status=$?
    rm -f "$pidfile"
    return $status
}

_diff_wrapper() {
    if [ "$HAS_COLORDIFF" ]
    then
        command diff "$@" 2>&1 | colordiff
    else
        command diff "$@"
    fi
}

_ls_wrapper() {
    test "$COMP_LINE" && return
    local args
    test "$LS_DIRECTORIES_FIRST" &&
        args="$args --group-directories-first"
    test "$LS_COLORS" &&
        args="$args --color=auto"
    LC_COLLATE=${LS_COLLATE:-C} /bin/ls $args "$@"
}

_cd_ls() {
    cd "$@" && ls
}

_sudo_wrapper() {
    local sudo_prompt='[sudo] password for %p@%h: '
    (sleep 10 && _sudo_cleanup &)
    command sudo -E -p "$sudo_prompt" "$@"
    _sudo_cleanup
}

_sudo_cleanup() {
    rm -f ~/.sudo_as_admin_successful
}

_toggle_prompt() {
    # toggle PS1
    if test "$SAVED_PS1"
    then
        PS1=$SAVED_PS1
        unset SAVED_PS1
    else
        SAVED_PS1=$PS1
        PS1='$ '
    fi
}

_pwsafe_echo() {
    key="$1"
    _pwsafe_wrapper -Epu "$key"
}

_pwsafe_copy() {
    key="$1"
    pw=$(_pwsafe_wrapper -pE "$key")
    if [ $? -eq 0 ]
    then
        echo -n "$pw" | xsel -ip
        echo -n "$pw" | xsel -ib
        echo OK
        sleep 5
        xsel -d -p
        xsel -d -b
    fi
}

rot13() {
    cat "$@" | tr 'a-zA-Z' 'n-za-mN-ZA-M'
}

# do previous command in arg/$PWD
ditto-there() {
    local arg="$1"
    local fmt='^ *[0-9]+ *[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2} '
    local cmd="$( history 2|head -1 | sed -r "$fmt")"
    local there="$arg$PWD"
    (cd "$there" &&  echo -e "> $there\n> $cmd" && eval "$cmd")
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

go() {
    local x
    for x; do xdg-open "$x"; done
}

hgprompt() {
    if [ "$1" = '-d' ]
    then
        rm_prompt_command 'hg prompt'
    else
        add_prompt_command 'hg prompt'
    fi
}

lines() {
    first=$1; shift
    second=$1; shift
    arg=${1:--}
    cat "$arg" | tail -n+$first | head -$(($second-$first+1))
}

# lib functions TODO: move somewhere central
reset-echo() {
    stty echo
    trap - INT
}

read-password() {
    trap reset-echo INT
    stty -echo
    read "$@"
    reset-echo
}

# alias for long running commands.  Use like so:
#  sleep 10; alert
alert() {
    local err=$?
    local icon
    [ $err = 0 ] && icon=terminal || icon=error
    local re='s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'
    local msg="$(history|tail -n1|sed -e "$re")"
    notify-send --urgency=low -i $icon "$msg"
}

_netcopy() {
    local src="$1"
    local mode
    local host
    local file

    case "$src" in
        *:*)
            mode=get
            host="${src/:*/}"
            path="${src#$host:}"
            ;;
        *)
            mode=put
            path="$src"
            host="$2"
            test "$host" && shift
            ;;
    esac

    test "$host" || { _netcopy_usage; return 1; }
    test "$path" || { _netcopy_usage; return 1; }
    test "$2"    && { _netcopy_usage; return 1; }
    f=_netcopy_$mode
    $f "$host" "$path"
}

_netcopy_usage() {
    echo "Usage: ncp host:path/file"
    echo "    OR ncp path/file host"
}

_netcopy_get() {
    local host=$1
    local path=$2
    local name=$(basename "$path")
    echo
    echo do get $host $path
    echo
    local r=$(ssh $host "stat -c '%s %y' $path")
    local s=${r/ *}
    local t="${r#$s }"
    ssh $host "nc -l 9090 < '$path'; md5sum '$path'" &
    sleep 2
    nc $host 9090 | pv -s $s > "$name"
    md5sum "$name"
    touch -d "$t" "$name"
    read -p "continue..."
}

_netcopy_put() {
    local host=$1
    local path=$2
    local name=$(basename "$path")
    echo
    echo put $host $path $name
    echo
    local t=$(stat -c %y "$path")
    local s="nc -l 9090 > '$name' && md5sum '$name' && touch -d '$t' '$name'"
    ssh $host "$s" &
    sleep 2
    pv "$path" | nc $host 9090
    md5sum "$path"
    read -p "continue..."
}

_file_paper() {
    src="$1"
    year=$2
    author="$3"
    title="$4"
    dst="$5"
    usage="args: src year author title dst"
    test $# -eq 5 || { echo "$usage"; return 1; }

    ext="$(echo "${src##*.}")"
    result="$year - $author - $title.$ext"
    dst="static/music/$result"
    mv -i "$src" "$dst"
    go "$dst"
}

