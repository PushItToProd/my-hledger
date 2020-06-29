#!/usr/bin/env bash
# A set of common configuration and utilities for the my-hledger scripts.
set -euo pipefail

# Set defaults for environmental config values if not set.
# LEDGER_DIR is the directory where we expect all our configuration and journal
# files to live.
: "${LEDGER_DIR:="$(dirname "$LEDGER_FILE")"}"
# JOURNALS_DIR is the location of the account-specific journals.
# TODO: refactor this to use `hledger files` instead
: "${JOURNALS_DIR:="$LEDGER_DIR/journals"}"
# CONFIG_FILE points to a script file that contains config options used by the
# helper scripts.
: "${CONFIG_FILE:="$LEDGER_DIR/helpers_config.sh"}"
# PROGNAME is the name of the running script.
: "${PROGNAME:="$(basename "$0")"}"

### Simple logging helpers

# Display a non-urgent note that will be somewhat emphasized in the output.
info() {
    echo "$(tput setaf 4)info: $*$(tput sgr0)" >&2
}

# Display an error message in red.
error() {
    echo "$(tput setaf 1)ERROR: $*$(tput sgr0)" >&2
}

# Display an error message and then exit.
fatal() {
    error "$*"
    exit 1
}

### Some utilities for checking system/script state

file_exists() {
  [[ -e "$1" ]]
}

is_set() {
    declare -p "$1" >/dev/null 2>/dev/null
}

required_var() {
    if ! is_set "$1"; then
        fatal "The config variable $1 is required, but is not set."
    fi
}

is_func() {
  declare -F "$1" >/dev/null 2>/dev/null
}

required_func() {
  if ! is_func "$1"; then
    fatal "The function $1 is required, but is not declared."
  fi
}

# Helper method meant to be called at the top level of a script. Returns true if
# the script is the root script that was invoked at the command line.
is_main() {
    [[ "${BASH_SOURCE[1]}" == "$0" ]]
}

# Find all .journal files in the journals/ directory adjacent to the ledger
# file.
list_journals() {
    # I would really like to use `hledger files` here, but that ends up
    # including the root hledger.journal, which then includes all the other
    # journals and causes hledger-validate-dates to fail due to the dates being
    # out of order.
    find "$JOURNALS_DIR" -iname '*.journal'
}

# Apply the given command to every journal given by `list_journals`.
apply() {
    for j in $(list_journals); do
        "$@" "$j"
    done
}

### Pre-run validation

if ! file_exists "$LEDGER_FILE"; then
  fatal "The LEDGER_FILE $LEDGER_FILE does not exist"
fi

if ! file_exists "$CONFIG_FILE"; then
    fatal "The config file $CONFIG_FILE does not exist." >&2
fi

### Load the configuration.
# shellcheck source=/home/joe/Documents/ledger/helpers_config.sh
source "$CONFIG_FILE"

# If this script gets run directly, expose `list_journals` and `apply` for
# testing.
if is_main; then
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
