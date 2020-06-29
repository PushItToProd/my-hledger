#!/usr/bin/env bash
# Lint all the shell scripts in this directory.

declare -a shell_scripts=()

# Since the scripts are named without extensions, we have to detect them using
# `file` instead.
for f in *; do
  if [[ "$(file "$f")" == *Bourne-Again* ]]; then
    shell_scripts+=("$f")
  fi
done

shellcheck -x "${shell_scripts[@]}"