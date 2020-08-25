#!/usr/bin/env bash
# Take the output of hledger-totals and validate it matches.
# TODO: actually run the validation

# shellcheck source=../common.sh
source "$(dirname "$0")/../common.sh"

print_line() {
  local -r bal="$1"
  local -r acct="$2"

  if [[ "$bal" == '$-'* ]]; then
    printf "$(tput setaf 1)%20s$(tput sgr0)  %s\n" "$bal" "$acct"
    return
  fi

  if [[ "$bal" == '$'* ]] || [[ "$bal" == 0 ]]; then
    printf "%20s  %s\n" "$bal" "$acct"
    return
  fi

  echo "$line"
}

is_not_balance_line() {
  local -r bal="$1"
  local -r acct="$2"

  # if the line starts with '===' or '---' it's a delimiter
  # if bal is null then the line is empty
  # if acct is null then it's a total line and we don't want to process it
  [[ "$bal" == "==="* ]] \
    || [[ "$bal" == "---"* ]] \
    || [[ ! "$bal" ]] \
    || [[ ! "$acct" ]]
}

process_line() {
  local line="$1"
  read -r bal acct <<<"$line"

  if is_not_balance_line "$bal" "$acct"; then
    print_line "$bal" "$acct"
    return
  fi

  print_line "$bal" "$acct"
}

while read -r line; do
  process_line "$line"
done < <(hledger totals)
