# shellcheck disable=SC1090

_luther_shell_helper_dir="$(dirname "$0")"

source "${_luther_shell_helper_dir}/aws.sh"
source "${_luther_shell_helper_dir}/acre.sh"

unset _luther_shell_helper_dir
