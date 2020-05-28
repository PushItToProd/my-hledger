# via https://stackoverflow.com/a/3352015
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

assert_eq() {
  if [[ "$1" != "$2" ]]; then
    local -r line="${BASH_LINENO[0]}"
    echo -n "Failed assertion (line $line): strings should be equal and aren't" >&2
    if [[ "${3-}" ]]; then
      echo " - $3" >&2
    else
      echo "" >&2
    fi
    diff <(echo "$1") <(echo "$2")
    exit 1
  fi
}

run_tests() {
  declare -F | grep -o '\<test:.*\>' | while read -r test_func; do
    echo "*** Running $test_func"
    "$test_func"
  done
}