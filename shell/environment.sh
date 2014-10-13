
# where else can this go?
LC_TIME=en_GB.UTF-8
export LC_TIME

_init_compat() {
    test "$HOSTNAME" || HOSTNAME=$(hostname)
    test "$UID" || UID=$(id -u)
}

_init_local() {
    LOCAL_USER=avdd
    source_first \
        $HOME/current/local/$HOSTNAME.sh \
        $HOME/current/local/$HOSTNAME/config.sh
}

_init_path() {
    test -d "$HOME/.local/bin" &&
        PATH="$HOME/.local/bin:$PATH" 
    export PATH
}

_init_dirs() {
    HISTPATH=~/log/history/$HOSTNAME
    RUNPATH=~/.local/run
    # posix mode: can't use bash expansion or arrays
    ensure_dirs     \
        ~/.cache    \
        ~/.config   \
        ~/.local    \
        ~/.local/share/vim/backup   \
        ~/.local/share/vim/swap     \
        ~/.local/share/vim/undo     \
        $HISTPATH

    local xdg=${XDG_RUNTIME_DIR:-}
    if [ "$xdg" ]
    then
        local runlink=
        [ -e "$RUNPATH" ] && runlink=$(readlink -f $RUNPATH)
        [ "$runlink" = "$xdg" ] || ln -sfn "$xdg" $RUNPATH
    fi

    ensure_dirs $RUNPATH $RUNPATH/ssh
    chmod 0700 $RUNPATH/ssh
}

_init_login() {
    local type_u=user type_h=local
    local login_u=$USER login_h=$HOSTNAME
    local expect=$LOCAL_USER

    case "$USER" in
        $expect)    type_u=user     login_u=      ;;
        *)          type_u=other    login_u=$USER ;;
    esac

    case "$SSH_CLIENT" in
        '') type_h=local    login_h=          ;;
        *)  type_h=remote   login_h=$HOSTNAME ;;
    esac

    test $USER = root && type_u=root

    LOGIN_TYPE=$type_u$type_h
    LOGIN_ABBREV=$login_u@$login_h
    test $LOGIN_ABBREV = @ && LOGIN_ABBREV=
}

_init_private() { :; }


