
shell_is_interactive() {
    case $- in
        *i*) return 0;;
        *)   return 1;;
    esac
}

has_command() {
    command -v "$1" &> /dev/null
}

ensure_dirs() {
    local d
    for d; do
        [ "$d" -a ! -d "$d" ] && mkdir -p $d
    done
}

read_one_line() {
    local name=$1 file=$2 line
    eval "$name=''"
    while IFS='\n' read line
    do
        eval "$name+=\$line"
        break
    done < "$file"
}

concat_string() {
    local name=$1 bit=
    shift
    eval "$name=''"
    for bit; do
        eval "$name=\"\$$name\$bit\"" 
    done
}

source_all() {
    local f
    for f; do
        . "$f"
    done
}

source_first() {
    local arg
    for arg; do
        if test -r "$arg"
        then
            . "$arg"
            return 0
        fi
    done
    return 1
}


