
ESC_CSI='\e['
ESC_FILL='\e[K'
ESC_RESET='\e[0m'
ESC_RV='\e[7m'
ESC_BOLD='\e[1m'
ESC_SAVE='\e[s'
ESC_RESTORE='\e[u'
ESC_BEL='\a'
ESC_TITLE='\e]2;'
ESC_GETPOS='\e[6n'

set_term_title() {
    local s=$(echo -n "${1//\\/\\\\}" | tr '[:cntrl:]' '?')
    echo -en "$ESC_TITLE$s$ESC_BEL" 1>&2
}

insert_newline() {
    local sym color s
    [ "$CLEAR_NEWLINE_COLOR" ] &&
        _coloresc color $CLEAR_NEWLINE_COLOR ||
        color="$ESC_RV"
    sym=${CLEAR_NEWLINE_SYMBOL:-$}
    s="$color$sym$ESC_RESET$ESC_FILL"
    printf "$s%$((COLUMNS-1))s\\r"
}

_colorcode() {
    local name=$1
    local value=$2
    test "$value" || return 0
    local fg=${value%%.*}
    local bg=${value##*.}
    test "$fg" && fg="38;5;$fg" || fg=39
    test "$bg" && bg="48;5;$bg" || bg=49
    local s="0;$fg;$bg"
    [[ $value = *b* ]] && s+=";1"
    [[ $value = *u* ]] && s+=";4"
    eval "$name='$s'"
}

_coloresc() {
    local name=$1
    local value=$2
    test "$value" || return 0
    local code
    _colorcode code "$value"
    eval "$name='\e[${code}m'"
}

# unused; kept as example of using a template variable
____coloresc() {
    local type=$1
    local name=$2
    local optname=${3}_COLOR_$type
    local value template
    eval "value=\$$optname"
    eval "$name=\${ESC_$type/_COLOR_/$value}"
}

# cursor placement (must be after fill)
#"$ESC_SAVE$ESC_CSI"'78G\A'"$ESC_RESTORE"

