_gopath() {
    go env GOPATH
}

alias aws_unset='unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN AWS_SESSION_TOKEN'
function aws_login {
    local role="${1:-testing}"
    local env_cmds
    if ! env_cmds="$(aws_unset; "$(_gopath)/bin/speculate" env --mfa --lifetime 43200 "$role")"; then
        return 1
    fi
    eval "$env_cmds"
}
alias aws_console='speculate console'

_display_notification() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"${message}\" with title \"${title}\""
}

# Run the command given by "$@" in the background
# https://unix.stackexchange.com/a/452568
_silent_background() {
    if [[ -n $ZSH_VERSION ]]; then  # zsh:  https://superuser.com/a/1285272/365890
        setopt local_options no_notify no_monitor
        "$@" &
        disown
    elif [[ -n $BASH_VERSION ]]; then  # bash: https://stackoverflow.com/a/27340076/5353461
        { 2>&3 "$@"& } 3>&2 2>/dev/null
    else
        "$@" &
    fi
}

_wait_clear_clipboard() {
    local lifetime="${CREDCOPY_CLIPBOARD_LIFETIME:-10}"
    sleep "$lifetime" && echo | pbcopy && _display_notification 'clipboard cleared' 'clipboard contents removed'
}

credcopy() {
    local creds
    creds="$(env | grep '^AWS_')"
    if [[ -z "$creds" ]]; then
        echo 'no credentials found in environment'
        return 1
    fi
    _silent_background _wait_clear_clipboard
    echo "$creds" | pbcopy
}

credpaste() {
    local creds
    creds="$(pbpaste | grep '^AWS_' | sed "s/AWS_/export AWS_/")"
    if [[ -z "$creds" ]]; then
        echo 'no credentials found in clipboard'
        return 1
    fi
    eval "$creds"
}

credhop() {
    export OLD_AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export OLD_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export OLD_AWS_SECURITY_TOKEN="$AWS_SECURITY_TOKEN"
    export OLD_AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"

    local env_cmds
    if ! env_cmds="$("$(_gopath)/bin/speculate" env "$@")"; then
        return 1
    fi
    eval "$env_cmds"
}

creddrop() {
    export AWS_ACCESS_KEY_ID="$OLD_AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$OLD_AWS_SECRET_ACCESS_KEY"
    export AWS_SECURITY_TOKEN="$OLD_AWS_SECURITY_TOKEN"
    export AWS_SESSION_TOKEN="$OLD_AWS_SESSION_TOKEN"
}
