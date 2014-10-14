#!/bin/bash

. ~/current/config/shell/init.sh

shopt -s nullglob dotglob

BACKUP=~/backup-$(date +%Y%m%d)

setup() {
    case "$HOSTNAME" in
        osake|test)
            setup_master;;
        *)
            setup_slave;;
    esac
}

setup_slave() {
    setup_basic
    setup_slave_ssh
}

setup_master() {
    setup_basic
    setup_new_ssh
    setup_desktop
}

setup_basic() {
    del .{login,logout}
    del .bash*
    del .vim*
    del .profile
    del .psqlrc
    del .lesshst
    del examples.desktop

    for name in profile bashrc bash_logout
    do
        link config/shell/$name.sh .$name
    done

    link config/vim .vim
    link config/postgresql/psqlrc .psqlrc
}

setup_slave_ssh() {
    test -L .ssh && del .ssh
    del .ssh/*
    mkdir -pvm 0700 .ssh
    link private/ssh/config.compat .ssh/config
    link private/ssh/authorized_keys .ssh
    link private/ssh/known_hosts .ssh
}

setup_new_ssh() {
    del .ssh
    link private/ssh .ssh
}

setup_desktop() {
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
            test -d "$BACKUP" || mkdir -pm 0700 "$BACKUP"
            mv -v "$target" "$BACKUP"
        fi
    done
}

(cd ~ && setup)

