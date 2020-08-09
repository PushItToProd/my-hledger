#!/usr/bin/env bash

readonly numeric_regex='^-?[0-9]+(\.[0-9]+)?$'
readonly dollar_amount_regex='^(\$-?[0-9,]+(\.[0-9]+)?|0)$'

is_numeric() {
  [[ "$1" =~ $numeric_regex ]]
}

is_dollar_amount() {
  [[ "$1" =~ $dollar_amount_regex ]]
}

pass() {
  echo " ✅ $(tput setaf 2)$*$(tput sgr0)"
}

fail() {
  echo " ❗ $(tput setaf 1)$*$(tput sgr0)"
}

assert() {
  if $1; then
    pass "$1"
  else
    fail "$1"
  fi
}

assert_not() {
  if ! $1; then
    pass "not $1"
  else
    fail "not $1"
  fi
}

assert_numeric() {
  assert "is_numeric $1"
  #if is_numeric "$1"; then
  #  pass "$1 matches correctly"
  #else
  #  fail "$1 failed to match!"
  #fi
}

assert_not_numeric() {
  assert_not "is_numeric $1"
  #if is_numeric "$1"; then
  #  fail "$1 matched but shouldn't!"
  #else
  #  pass "$1 correctly excluded"
  #fi
}

assert_numeric 10
assert_numeric 10.00
assert_numeric 1234
assert_numeric 12.34
assert_numeric 0
assert_not_numeric abc
assert_not_numeric 12.34.56

assert 'is_dollar_amount $10'
assert 'is_dollar_amount $10.00'
assert_not 'is_dollar_amount 10'
assert_not 'is_dollar_amount $10.00.00'

single_acct_bal="$(hledger bal --flat -ERCP Assets:Checking:Chase -N --format '%(total)')"
assert "is_dollar_amount $single_acct_bal"

multi_acct_bal="$(hledger bal --flat -ERCP Assets -N --format '%(total)')"
assert_not "is_dollar_amount '$multi_acct_bal'"

assert "is_dollar_amount 0"