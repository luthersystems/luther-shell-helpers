GOPATH="$(go env GOPATH)"
alias aws_unset='unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN AWS_SESSION_TOKEN'
function aws_login {
    role="${1:-testing}"
    envCmds="$(aws_unset; "${GOPATH}/bin/speculate" env --mfa --lifetime 43200 "$role")"
    eval "$envCmds"
}
alias aws_console='speculate console'

alias credcopy='env | grep "^AWS_" | pbcopy'
alias credpaste='eval "$(pbpaste | sed "s/AWS_/export AWS_/")"; echo | pbcopy'

function credhop {
    export OLD_AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export OLD_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export OLD_AWS_SECURITY_TOKEN="$AWS_SECURITY_TOKEN"
    export OLD_AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"

    envCmds="$("${GOPATH}/bin/speculate" env "$@")"
    eval "$envCmds"
}

function creddrop {
    export AWS_ACCESS_KEY_ID="$OLD_AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$OLD_AWS_SECRET_ACCESS_KEY"
    export AWS_SECURITY_TOKEN="$OLD_AWS_SECURITY_TOKEN"
    export AWS_SESSION_TOKEN="$OLD_AWS_SESSION_TOKEN"
}

