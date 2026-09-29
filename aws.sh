#!/usr/bin/env bash

# LUTHER_AWS_ACCOUNT_MAP is a file path containing lines of space delimited
# pairs:
#   ALIAS   ACCOUNTID
LUTHER_AWS_ACCOUNT_MAP="${LUTHER_AWS_ACCOUNT_MAP:-$HOME/.aws/accounts}"
function lsh_aws_account_map {
  # Strip any comments and extra trailing fields.
  [[ -r "$LUTHER_AWS_ACCOUNT_MAP" ]] || return 1
  grep -vE '^\s*#' "$LUTHER_AWS_ACCOUNT_MAP" 2>/dev/null | awk '{print $1 "\t" $2}'
}

# Private helpers are named lsh_* rather than _*: shells that snapshot the
# user's functions (e.g. Claude Code's `!` prompt) skip underscore-prefixed
# names as completion functions, and every public function here needs them.
lsh_gopath() {
  go env GOPATH
}

# aws_unset clears any aws session variables set in the current environment.
alias aws_unset='unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN AWS_SESSION_TOKEN'

# aws_login creates an mfa-secured aws session and sets env variables for the
# aws cli and sdks. Usage: aws_login [role] [mfa-code]. Pass the code when the
# shell cannot prompt for it (e.g. `! aws_login admin 123456` in Claude Code).
function aws_login {
  local role="${1:-dev}"
  local mfa_args=()
  [[ -n "$2" ]] && mfa_args=(--mfacode "$2")
  local env_cmds
  if ! env_cmds="$(
    aws_unset
    "$(lsh_gopath)/bin/speculate" env --mfa "${mfa_args[@]}" --lifetime 3600 "$role"
  )"; then
    return 1
  fi
  eval "$env_cmds"
}

aws_console() (
  set -eo pipefail
  acc=$1
  if [ -n "$acc" ]; then
    aws_jump "$acc" admin
  fi
  "$(lsh_gopath)/bin/speculate" console
)

# aws_account_lookup locates a named aws account, aliased in the account
# mapping file (see LUTHER_AWS_ACCOUNT_MAP).
function aws_account_lookup {
  local acct="$1"
  local row
  row=$(lsh_aws_account_map |
    awk -v ACCT="$acct" '$1 == ACCT' |
    head -n 1)
  if [[ -z "$row" ]]; then
    echo "unable to locate aws account $acct" >&2
    return 1
  fi
  echo "$row"
}

# aws_jump is a wrapper around credhop that utilizes LUTHER_AWS_ACCOUNT_MAP to
# assume a role in a named aws account.  Use creddrop to return to the original
# account/session.
function aws_jump {
  local acct="$1"
  if [[ -z "$acct" ]]; then
    echo "a non-empty account name must be provided" >&2
    return 1
  fi
  local role="$2"
  if [[ -z "$role" ]]; then
    echo "a non-empty role name must be provided" >&2
    return 1
  fi
  local acctid
  acctid=$(aws_account_lookup "$acct" | cut -f2)
  [[ -n "$acctid" ]] || return 1
  credhop --account "$acctid" "$role"
}

lsh_display_notification() {
  local title="$1"
  local message="$2"
  osascript -e "display notification \"${message}\" with title \"${title}\""
}

# Run the command given by "$@" in the background
# https://unix.stackexchange.com/a/452568
lsh_silent_background() {
  if [[ -n $ZSH_VERSION ]]; then # zsh:  https://superuser.com/a/1285272/365890
    setopt local_options no_notify no_monitor
    "$@" &
    disown
  elif [[ -n $BASH_VERSION ]]; then # bash: https://stackoverflow.com/a/27340076/5353461
    { 2>&3 "$@" & } 3>&2 2>/dev/null
  else
    "$@" &
  fi
}

lsh_wait_clear_clipboard() {
  local lifetime="${CREDCOPY_CLIPBOARD_LIFETIME:-10}"
  sleep "$lifetime" && echo | pbcopy && lsh_display_notification 'clipboard cleared' 'clipboard contents removed'
}

# credcopy copies aws session environment variables to to the macos system
# clipboard.
credcopy() {
  local creds
  creds="$(env | grep '^AWS_')"
  if [[ -z "$creds" ]]; then
    echo 'no credentials found in environment'
    return 1
  fi
  lsh_silent_background lsh_wait_clear_clipboard
  echo "$creds" | pbcopy
}

# credpaste sets aws session environment variables extracted from the macos
# system clipboard contents.
credpaste() {
  local creds
  creds="$(pbpaste | grep '^AWS_' | sed "s/AWS_/export AWS_/")"
  if [[ -z "$creds" ]]; then
    echo 'no credentials found in clipboard'
    return 1
  fi
  eval "$creds"
}

# A stack of aws session credentials
OLD_AWS_CREDS=""

lsh_stackpush() { printf "%s\t%s\n" "$1" "$2"; }
lsh_stackpop() { echo "$1" | cut -f2-; }
lsh_stacktop() { echo "$1" | cut -f1; }

lsh_aws_session_json() {
  jq -nc '{"id":$id,"k":$k,"su":$su,"ss":$ss}' \
    --arg id "$AWS_ACCESS_KEY_ID" \
    --arg k "$AWS_SECRET_ACCESS_KEY" \
    --arg su "$AWS_SECURITY_TOKEN" \
    --arg ss "$AWS_SESSION_TOKEN"
}
lsh_aws_session_from_json() {
  local json
  if ! json="$(echo "$1" | jq -c '.' | head -n 1)"; then
    echo "argument contains invalid json" >&2
    return 1
  fi
  AWS_ACCESS_KEY_ID="$(echo "$json" | jq -r '.id')" || return 1
  AWS_SECRET_ACCESS_KEY="$(echo "$json" | jq -r '.k')" || return 1
  AWS_SECURITY_TOKEN="$(echo "$json" | jq -r '.su')" || return 1
  AWS_SESSION_TOKEN="$(echo "$json" | jq -r '.ss')" || return 1
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN AWS_SESSION_TOKEN
}

# credhop saves the current aws session variable values and repopulates them
# for a new session created by calling `speculate env` with the given
# arguments.
credhop() {
  local obj
  if [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
    obj="$(lsh_aws_session_json)" || return 1
    OLD_AWS_CREDS="$(lsh_stackpush "$obj" "$OLD_AWS_CREDS")"
  fi
  local env_cmds
  if ! env_cmds="$("$(lsh_gopath)/bin/speculate" env "$@")"; then
    return 1
  fi
  eval "$env_cmds"
}

# creddrop restores aws session variable values saved previously by calling
# `credhop`.
creddrop() {
  lsh_aws_session_from_json "$(lsh_stacktop "$OLD_AWS_CREDS")" || return 1
  OLD_AWS_CREDS="$(lsh_stackpop "$OLD_AWS_CREDS")"
}
