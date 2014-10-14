
BACKUP_SYNC_COMMAND=
BACKUP_SYNC_DELAY=10

_backup_sync_init() {
    local d=$1
    test "$d" || { echo "require arg"; return 1; }
    test -d "$d" || { echo "dir '$d' missing"; return 1; }
    BACKUP_SYNC_COUNTER=$d/backup_sync_history_counter
    BACKUP_SYNC_LOCKFILE=$d/backup_sync_lock
}

_backup_sync_control() {
    _backup_sync_configured || { echo disabled; return 1; }
    test "$SUDO_USER" && { echo sudo not allowed; return 1; }
    local arg=${1:-}
    if [[ "$arg" = @(off|0) ]]
    then
        _backup_sync_lock_wait
    else
        _backup_sync_unlock_wait
        _backup_sync_command_lock
    fi
}

_backup_sync_hook() {
    _backup_sync_configured &&
        _backup_sync_incr_counter &&
        ! _backup_sync_locked &&
        (cd; _backup_sync_command_lock &)
}

_backup_sync_status() {
    _backup_sync_configured || return 1
    local __name=$1
    _backup_sync_get_counter count
    eval "$__name=$count"
    ! _backup_sync_locked
}

_backup_sync_incr_counter() {
    local file=$BACKUP_SYNC_COUNTER
    local max=$BACKUP_SYNC_DELAY
    local count
    _backup_sync_get_counter count

    if [[ ! -f $file || $HISTFILE -nt $file ]]
    then
        ((++count))
        echo $count > $file
    fi
    ((count >= max))
}

_backup_sync_run_command() {
    local before after
    _backup_sync_get_counter before
    if $BACKUP_SYNC_COMMAND
    then
        _backup_sync_get_counter after
        ((after-=before))
        _backup_sync_put_counter $after
        _backup_sync_unlock
    fi
}

_backup_sync_command_lock() {
    (
        flock -n 201 || { echo 'locked'; exit 1; }
        _backup_sync_run_command
    ) 201>$BACKUP_SYNC_LOCKFILE
}

_backup_sync_lock_wait() {
    local locked=0
    _backup_sync_locked && echo -n "waiting for lock ... " && ((locked=1))
    (flock -x 201) 201> $BACKUP_SYNC_LOCKFILE
    ((locked)) && echo ok || true
}

_backup_sync_unlock_wait() {
    _backup_sync_lock_wait && _backup_sync_unlock
}

_backup_sync_unlock() {
    rm -f $BACKUP_SYNC_LOCKFILE
}

_backup_sync_locked() {
    test "$SUDO_USER" || test -f $BACKUP_SYNC_LOCKFILE
}

_backup_sync_get_counter() {
    local line name=$1
    if [[ ! -r "$BACKUP_SYNC_COUNTER" ]]
    then
        eval "$name=0"
        return
    fi
    # get line from file without a subshell
    while IFS=$'\n' read line
    do
        eval "$name=\$line" && return
    done < "$BACKUP_SYNC_COUNTER"
}

_backup_sync_put_counter() {
    echo $1 > "$BACKUP_SYNC_COUNTER"
}

_backup_sync_configured() {
    test "$BACKUP_SYNC_COMMAND"
}

