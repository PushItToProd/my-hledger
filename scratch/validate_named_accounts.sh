#!/usr/bin/env bash
# Take the output of hledger-totals and validate it matches.
# TODO: actually run the validation

# shellcheck source=../common.sh
#source "$(dirname "$0")/../common.sh"
# shellcheck source=../hledger-validate-assertions
source "$(dirname "$0")/../hledger-validate-assertions"

get_account_journal() {
  grep -r --files-with-matches "#account $1" "$JOURNALS_DIR" | head -n 1 || true
}

# Print the current line, formatted appropriately. This replicates the
# formatting of hledger-totals.
# Globals:
#   $bal
#   $acct
#   $line
_print_line() {
  # If it's a negative balance, print it as a formatted balance line with the
  # amount in red.
  if [[ "$bal" == '$-'* ]]; then
    printf "$(tput setaf 1)%20s$(tput sgr0)  %s" "$bal" "$acct"
    return
  fi

  # If balance is a dollar amount or zero, print it as a formatted balance line.
  if [[ "$bal" == '$'* ]] || [[ "$bal" == 0 ]]; then
    printf "%20s  %s" "$bal" "$acct"
    return
  fi

  printf '%s' "$line"
}

# _print_line but with a newline at the end.
print_line() {
  _print_line
  echo
}

# Globals:
#   $bal
#   $acct
is_not_balance_line() {
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
  local bal acct journal_file
  read -r bal acct <<<"$line"

  if is_not_balance_line "$bal" "$acct"; then
    print_line "$bal" "$acct"
    return
  fi

  _print_line "$bal" "$acct"

  # get journal file
  journal_file="$(get_account_journal "$acct")"

  # print a newline and continue if no journal was found
  if [[ ! "$journal_file" ]]; then
    echo
    return
  fi

  local -r asserted_balance="$(get_asserted_balance "$journal_file")"
  if [[ ! "$asserted_balance" ]]; then
    debug "No asserted balance in $journal_file"
    echo
    return
  fi

  if ! bal_equal "$asserted_balance" "$bal"; then
    echo " $(tput setaf 1)(assertions!)$(tput sgr0)"
    return
  fi

  # print a newline
  echo
}

while read -r line; do
  process_line "$line"
done < <(hledger totals)
