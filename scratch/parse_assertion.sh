#!/usr/bin/env bash
# An experiment with parsing balance assertions from hledger journals.
# Basically I want to put something like
#     ; #assert balance=$100
# at the end of a journal file and then validate that the account's balance
# matches.

dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

journal="$dir/../sample_journals/with_assert.journal"

# parse out directives
read_asserts() {
  grep -E ';[[:space:]]*#assert' "$1"
}

parse_assert() {
  local re="#assert balance=(.*)"
  [[ "$1" =~ $re ]]
  local amount="${BASH_REMATCH[1]}"
  echo "$amount"
}

while read -r assertion; do
  parse_assert "$assertion"
done < <(read_asserts "$journal")
