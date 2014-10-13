#!/bin/bash

. ~/current/config/shell/init.sh

shopt -s nullglob dotglob

TRASH=~/backup-$(date +%Y%m%d)

spec() {
    del .{login,logout}
    del .bash*
    del .vim*
    del .ssh
    del .psqlrc

    for name in profile bashrc bash_logout
    do
        link config/shell/$name.sh .$name
    done

    link config/vim .vim
    link config/postgresql/psqlrc .psqlrc
    link private/ssh .ssh

    mkdir -pv current/local/$HOSTNAME
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

link() {
    ln -sfnv current/$1 $2
}

(cd ~ && spec)

