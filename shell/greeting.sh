
_repeat_string() {
    local name count text i
    name=$1
    count=$2
    text=$3
    #eval "unset $name"
    eval "$name=''"
    for ((i=0;i<$count;++i))
    do
        eval "$name+=\$text"
    done
}

_centre_pad() {
    local name=$1 text=$2
    local cols=${COLUMNS:-80}
    eval "(($name = $COLUMNS / 2 - ${#msg} / 2))"
}

_greeting() {
    local indent line msg pad lc tc
    _coloresc lc 45.
    _coloresc tc 42.
    # test login, etc
    msg='Hello'
    _centre_pad pad "$msg"
    _repeat_string indent $pad ' '
    _repeat_string line ${#msg} =

    echo
    echo -e "$indent$lc$line$ESC_RESET"
    echo -e "$indent$tc$msg$ESC_RESET"
    echo -e "$indent$lc$line$ESC_RESET"
    echo
}

