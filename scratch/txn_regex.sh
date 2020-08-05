#!/usr/bin/env bash
# Sketching some ideas for parsing transactions using bash.

printa() {
  for item; do
    echo "$item"
  done
}

process_line() {
  local -r line="$1"
  re="([0-9]{4}-[0-9]{2}-[0-9]{2})( [!*])?(.*)"
  [[ "$line" =~ $re ]]
  date="${BASH_REMATCH[1]}"
  status="${BASH_REMATCH[2]}"
  desc="${BASH_REMATCH[3]}"
  echo "$line"
  echo "  Date: $date"
  echo "  Status:$status"
  echo "  Description:$desc"
}

process_line "2020-08-04 ! last.fm"
echo
process_line "2020-08-02 * G Suite"
echo
process_line "2020-08-02 Test"