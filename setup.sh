#!/bin/bash

. ~/current/config/shell/init.sh

shopt -s nullglob dotglob

TRASH=~/backup-$(date +%Y%m%d)

setup() {
    case "$HOSTNAME" in
        osake|another-desktop)
            setup_desktop;;
        *)
            setup_basic;;
    esac
}

setup_basic() {
    del .{login,logout}
    del .bash*
    del .vim*
    del .psqlrc
    del .lesshst
    del .ssh/*
    test -d .ssh || del .ssh

    for name in profile bashrc bash_logout
    do
        link config/shell/$name.sh .$name
    done

    link config/vim .vim
    link config/postgresql/psqlrc .psqlrc

    mkdir -pvm 0700 .ssh
    link private/ssh/config.compat .ssh/config
    link private/ssh/authorized_keys .ssh
    link private/ssh/known_hosts .ssh

    mkdir -pv current/local/$HOSTNAME
}

setup_desktop() {
    setup_basic

    del Desktop Documents Downloads

    ln -sfnv log/new Desktop
    ln -sfnv log/new Documents
    ln -sfnv .       Downloads
}

link() {
    local target=$1
    local link=$2

    if [ -d "$link" ]
    then
        link=$link/$(basename $target)
    fi
    local linkdir=$(dirname $link)
    local prefix=
    while [ "$linkdir" != . ]
    do
        prefix=../$prefix
        linkdir=$(dirname $linkdir)
    done
    target=current/$target
    ln -sfnv $prefix$target $link
}

del() {
    local target
    for target
    do
        [ -e "$target" ] || continue
        [ -k "$target" ] && continue

        if [ -L "$target" ]
        then
            rm -f "$target"
        else
            test -d "$TRASH" || mkdir -pm 0700 "$TRASH"
            mv -v "$target" "$TRASH"
        fi
    done
}

(cd ~ && setup)

