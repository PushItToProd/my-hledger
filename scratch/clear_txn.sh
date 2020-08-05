#!/usr/bin/env bash
# Find a pending transaction with a particular pattern and mark it cleared.
set -euo pipefail

#ledger_file="$1"
#txn_match="$2"
ledger_file="$HOME/Documents/ledger/journals/chase/freedom.journal"
txn_match="last"

while IFS="" read -r line || [ -n "$line" ]; do
  if [[ "$line" == *"! $txn_match"* ]]; then
    echo "${line/!/*}"
  fi
done < "$ledger_file"