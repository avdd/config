
# extracted from git's bash completion contrib
# don't redefine it if it's there already
if [[ -z $BASH_VERSION || -z "$(type -t __gitdir)" ]]; then
    __gitdir ()
    {
        if [ -z "${1-}" ]; then
            if [ -n "${__git_dir-}" ]; then
                echo "$__git_dir"
            elif [ -d .git ]; then
                echo .git
            else
                git rev-parse --git-dir 2>/dev/null
            fi
        elif [ -d "$1/.git" ]; then
            echo "$1/.git"
        else
            echo "$1"
        fi
    }
fi

# cd hook
__git_ps1_gitdir() {
    local g=$(__gitdir)
    unset GIT_PS1_GITDIR
    test "$g" && GIT_PS1_GITDIR=$g
}

# compute git status and set environment variables
__git_ps1_vars() {
    local g=$GIT_PS1_GITDIR

    if test -z "$g"
    then
        unset GIT_PS1_STATUS
        unset GIT_PS1_BRANCH
        unset GIT_PS1_SUBJECT
        unset GIT_PS1_TOPLEVEL
        unset GIT_PS1_NAME
        unset GIT_PS1_PREFIX
        return
    fi

    local rebase=0
    local interactive=0
    local apply=0
    local merge=0
    local bisect=0
    local gitdir=0
    local bare=0
    local work=0
    local staged=0
    local unstaged=0
    local new=0
    local untracked=0
    local stashed=0
    local toplevel=
    local subject=
    local branch=
    local prefix=

    # assess position in repository
    test "$(git rev-parse --is-inside-git-dir 2>/dev/null)" = true &&
        gitdir=1
    test $gitdir -eq 1 &&
        "$(git rev-parse --is-bare-repository  2>/dev/null)" = true &&
        bare=1
    test $gitdir -eq 0 &&
        "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true &&
        work=1

    # gitdir corner case
    test "$g" == . && {
        if test "${PWD##*/}" == .git
        then
            # inside .git: not a bare repository!
            # weird: --is-bare-repository returns true regardless
            bare=0
            g=$PWD
        else
            # really a bare repository
            bare=1
            g=$PWD
        fi
    }

    # make relative path absolute
    test "${g/#\//}" == "$g" && g=$PWD/$g
    g=${g/%\//} # strip trailing slash, if any

    # find base dir (toplevel)
    test $bare -eq 1 && toplevel=$g
    test $bare -eq 0 && toplevel=${g%/*}

    # find relative path within toplevel
    prefix=${PWD/#$toplevel/}
    prefix=${prefix/#\//} # strip starting slash
    test -z "$prefix" && prefix=. # toplevel == prefix

    # get the current branch, or whatever describes HEAD
    branch=$(__git_ps1_branch)

    test -d "$g/rebase-merge" &&
        rebase=1 merge=1 subject=$(cat "$g/rebase-merge/head-name")
    test $rebase -eq 1 && -f "$g/rebase-merge/interactive" &&
        interactive=1 merge=0
    test -d "$g/rebase-apply" &&
        rebase=1 apply=1
    test $apply  -eq 1 && -f "$g/rebase-apply/applying" &&
        rebase=0
    test $apply  -eq 1 && -f "$g/rebase-apply/rebasing" &&
        apply=0
    test $rebase -eq 0 && -f "$g/MERGE_HEAD" &&
        merge=1
    test $rebase -eq 0 && -f "$g/BISECT_LOG" &&
        bisect=1

    # working directory status
    if test $work -eq 1
    then
        ## dirtiness, if config allows it
        if test -n "${GIT_PS1_SHOWDIRTYSTATE-}"
        then
            # unstaged files
            git diff --no-ext-diff --ignore-submodules --quiet --exit-code ||
                unstaged=1

            if git rev-parse --quiet --verify HEAD >/dev/null
            then
                # staged files
                git diff-index --cached --quiet --ignore-submodules HEAD -- ||
                    staged=1
            else
                # no current commit, we're a freshly init'd repo
                new=1
            fi
        fi

        ## stash status
        if test -n "${GIT_PS1_SHOWSTASHSTATE-}"
        then
            git rev-parse --verify refs/stash >/dev/null 2>&1 &&
                stashed=1
        fi

        ## untracked files
        if test -n "${GIT_PS1_SHOWUNTRACKEDFILES-}"
        then
            test -n "$(git ls-files --others --exclude-standard)" &&
                untracked=1
        fi
    fi

    GIT_PS1_STATUS=""
    test $rebase      -eq 1 && GIT_PS1_STATUS+=R
    test $interactive -eq 1 && GIT_PS1_STATUS+=i
    test $apply       -eq 1 && GIT_PS1_STATUS+=A
    test $merge       -eq 1 && GIT_PS1_STATUS+=M
    test $bisect      -eq 1 && GIT_PS1_STATUS+=B
    test $gitdir      -eq 1 && GIT_PS1_STATUS+=g
    test $bare        -eq 1 && GIT_PS1_STATUS+=b
    test $work        -eq 1 && GIT_PS1_STATUS+=w
    test $staged      -eq 1 && GIT_PS1_STATUS+=s
    test $unstaged    -eq 1 && GIT_PS1_STATUS+=u
    test $new         -eq 1 && GIT_PS1_STATUS+=n
    test $untracked   -eq 1 && GIT_PS1_STATUS+=t
    test $stashed     -eq 1 && GIT_PS1_STATUS+=h
    GIT_PS1_BRANCH=$branch
    GIT_PS1_SUBJECT=$subject
    GIT_PS1_TOPLEVEL=$toplevel
    GIT_PS1_NAME=${toplevel##*/}
    GIT_PS1_PREFIX=$prefix
}

__git_ps1_describe() {
    case "${GIT_PS1_DESCRIBE_STYLE-}" in
        contains)
            git describe --contains HEAD ;;
        branch)
            git describe --contains --all HEAD ;;
        describe)
            git describe HEAD ;;
        *|default)
            git describe --exact-match HEAD ;;
    esac 2>/dev/null
}

__git_ps1_branch() {
    local g="$1"
    local branch
    branch=$(git symbolic-ref HEAD 2>/dev/null  ||
                __git_ps1_describe              ||
                git rev-parse --short HEAD      ||
                echo unknown)
    echo ${branch##refs/heads/}
}

