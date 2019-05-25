#!/usr/bin/env bash
set -euo pipefail

: "${LEDGER_DIR:="$(dirname "$LEDGER_FILE")"}"
: "${JOURNALS_DIR:="$LEDGER_DIR/journals"}"
: "${CONFIG_FILE:="$LEDGER_DIR/helpers_config.sh"}"

if [[ -e "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "WARNING: The config file $CONFIG_FILE does not exist." >&2
fi

# Find all .journal files in the journals/ directory adjacent to the ledger
# file.
list_journals() {
    find "$JOURNALS_DIR" -iname '*.journal'
}

# Apply the given command to every journal given by `list_journals`.
apply() {
    for j in $(list_journals); do
        "$@" "$j"
    done
}

fatal() {
    echo "$(tput setaf 1)ERROR: $@$(tput sgr0)" >&2
    exit 1
}

is_set() {
    [[ "${!1:+is_set}" == "is_set" ]]
}

required_var() {
    if ! is_set "$1"; then
        fatal "The config variable $1 is required, but is not set."
    fi
}

# Helper method meant to be called at the top level of a script. Returns true if
# the script is the root script that was invoked at the command line.
is_main() {
    [[ "${BASH_SOURCE[1]}" == "$0" ]]
}

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
    case "${1:-}" in
        list_journals)
            shift
            list_journals "$@"
            ;;
        apply)
            shift
            apply "$@"
            ;;
        *) fatal "You must specify a command: list_journals, apply"
            ;;
    esac
fi