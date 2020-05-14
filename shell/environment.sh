_init_compat() {
    test "$HOSTNAME" || HOSTNAME=$(hostname -s)
    test "$UID" || UID=$(id -u)
    # someone set us up the wrong
    case "$HOSTNAME" in
        *.modernnoise.com)
        HOSTNAME=${HOSTNAME%%.modernnoise.com}
        ;;
    esac
}

_init_local() {
    LOCAL_USER=avdd
    source_first \
        $HOME/current/local/$HOSTNAME.sh \
        $HOME/current/local/$HOSTNAME/config.sh
}

_init_path() {
    if [[ -d "$HOME/.local/bin" ]] && [[ $PATH != *$USER/.local/bin* ]]
    then
        PATH="$HOME/.local/bin:$PATH" 
    fi
    export PATH
}

_init_dirs() {
    RUNPATH=~/.local/run
    # posix mode: can't use bash expansion or arrays
    #~/.cache    \
    #~/.config   \
    [[ -d ~/_store ]] || return
    ensure_dirs     \
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

    ensure_dirs $RUNPATH $RUNPATH/ssh $RUNPATH/thumbnails
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
        *)  type_h=remote   login_h=@$HOSTNAME ;;
    esac

    test $USER = root && type_u=root

    LOGIN_TYPE=$type_u$type_h
    LOGIN_ABBREV=$login_u$login_h
    #test $LOGIN_ABBREV = @ && LOGIN_ABBREV=
}

_init_private() { :; }


