GOPATH="$(go env GOPATH)"
alias aws_unset='unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN AWS_SESSION_TOKEN'
function aws_login {
    role="${1:-testing}"
    envCmds="$(aws_unset; "${GOPATH}/bin/speculate" env --mfa --lifetime 43200 "$role")"
    eval "$envCmds"
}
alias aws_console='speculate console'
