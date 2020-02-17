
# zsh style
chpwd() { :; }
preexec() { :; }
precmd() { :; }

__preexec_trap () {
    if [ "${COMP_LINE:-}" ]; then return; fi
    if [ -z "$__PREEXEC_INTERACTIVE" ]; then return; fi
    __PREEXEC_INTERACTIVE=
    if [ "$BASH_COMMAND" == __prompt_command ]; then return; fi
    # at this point the command is likely interactive
    preexec
}

__prompt_command() {
    precmd
    __PREEXEC_INTERACTIVE=yes
}

__install_hooks() {
    __install_cd_hook
    __install_prompt_hook
    __install_preexec_hook
}

__install_preexec_hook() {
    set -o functrace
    #shopt -s extdebug
    trap __preexec_trap DEBUG
}

__install_prompt_hook() {
    PROMPT_COMMAND=__prompt_command
}

__install_cd_hook() {
    cd() {
        builtin cd "$@"
        local rc=$?
        test $rc -eq 0 && chpwd
        return $rc
    }
    pushd() {
        builtin pushd "$@"
        local rc=$?
        test $rc -eq 0 && chpwd
        return $rc
    }
    popd() {
        builtin popd "$@"
        local rc=$?
        test $rc -eq 0 && chpwd
        return $rc
    }
}

return

# dragons

# using hooks (experimental & not very useful?)

declare -a __CD_HOOKS
declare -a __PREEXEC_HOOKS
declare -a __PROMPT_HOOKS

chpwd() {
    __run_hooks "${__CD_HOOKS[@]}"
}

preexec() {
    __run_hooks "${__PREEXEC_HOOKS[@]}"
}

precmd() {
    COMMAND_ERROR=$?
    __run_hooks "${__PROMPT_HOOKS[@]}"
}

__add_cd_hook() {
    __CD_HOOKS+=("$@")
}

__add_preexec_hook() {
    __PREEXEC_HOOKS+=("$@")
}

__add_prompt_hook() {
    __PROMPT_HOOKS+=("$@")
}

__rm_cd_hook() {
    for i in ${!__CD_HOOKS[@]}
    do
        if [ "${__CD_HOOKS[$i]}" = "$1" ]
        then
            unset __CD_HOOKS[$i]
            __CD_HOOKS=("${__CD_HOOKS[@]}")
            break
        fi
    done
}

__rm_preexec_hook() {
    for i in ${!__PREEXEC_HOOKS[@]}
    do
        if [ "${__PREEXEC_HOOKS[$i]}" = "$1" ]
        then
            unset __PREEXEC_HOOKS[$i]
            __PREEXEC_HOOKS=("${__PREEXEC_HOOKS[@]}")
            break
        fi
    done
}

__rm_prompt_hook() {
    for i in ${!__PROMPT_HOOKS[@]}
    do
        if [ "${__PROMPT_HOOKS[$i]}" = "$1" ]
        then
            unset __PROMPT_HOOKS[$i]
            __PROMPT_HOOKS=("${__PROMPT_HOOKS[@]}")
            break
        fi
    done
}

__run_hooks() {
    local hook_expr
    for hook_expr; do
        eval "$hook_expr"
    done
}

