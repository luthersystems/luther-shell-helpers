#!/usr/bin/env bash

# shellcheck disable=SC1090

script="${BASH_SOURCE[0]:-$0}"
_luther_shell_helper_dir="$(dirname "$script")"

source "${_luther_shell_helper_dir}/aws.sh"

unset _luther_shell_helper_dir
