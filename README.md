# my-hledger

A collection of helper scripts for my hledger setup.

> 🚨 Warning: I update this README far less often than the actual scripts, so
> this information may be incredibly outdated.

## A brief overview of my hledger setup

The entrypoint for my hledger journals is a file named `hledger.journal` stored
in my `~/ledger` directory. This defines all my aliases and accounts and
includes all of my journal files.

My journal files are stored at `~/ledger/journals`, organized into directories
by bank or provider. I also have a `budget.journal` file that I use to manage my
envelope budgets.

My accounts are grouped into the following general structure:

* Assets
    * Checking
    * Investment
    * Savings
* Budget
    * Buffer
    * Core
    * Fun
    * Savings
* Equity
    * Opening balances
* Expenses -- mirrors categories under "Budget"
* Income
    * Salary
* Liabilities
    * Credit
    * Loans

The Assets, Equity, Expenses, Income, and Liabilities accounts are hopefully
self-explanatory. The Budget account is used for my envelope budgeting system,
inspired by [YNAB](https://www.youneedabudget.com/the-four-rules/).

<!-- TODO: illustrate transaction format -->

## The Scripts

Each script has a prefix of `hledger-`, which allows it to be picked up as an
hledger subcommand if it's on the path.

* **hledger-bills** - Checks if transactions matching queries in a config file have been
  made in the current month.
* **hledger-enter** - Quickly inserts common transactions.
* **hledger-enter-groceries** - Quickly inserts grocery transactions.
* **hledger-envelopes** - Displays balances of envelope budget accounts.
* **hledger-expenses** - Summarizes monthly expenditures by expense account.
* **hledger-git** - Wrapper that runs git in my ledger directory.
* **hledger-grep** - Wrapper than runs grep on my journal files.
* **hledger-income** - Shows net revenues and expenses by income and expense
  account by month.
* **hledger-launch** - Launches a web browser with banking sites and a text
  editor with all journal files open.
* **hledger-loan-progress** - Shows my student loan balances by month.
* **hledger-loans** - Shows my current student loan balances.
* **hledger-man** - Wrapper for viewing hledger help info.
* **hledger-pending** - Prints pending entries.
* **hledger-recent** - Prints recent entries.
* **hledger-summary** - Displays an income statement summarizing my spending for
  the year so far.
* **hledger-totals-raw** - Displays main asset and liability account balances in
  a way that will match my banks' reported balances.
  * Asset account balances reflect all pending transactions immediately, but
    liability accounts only reflect the total of cleared transactions, so this
    script calls `hledger balance` twice with separate flags for each type of
    account.
* **hledger-totals** - Wrapper for `hledger-totals-raw` that validates account
  balances using the logic from `hledger-validate-assertions`.
* **hledger-true-balances** - Displays account balances with all transaction
  statuses included so I can see what my balances will actually be once all
  currently-known transactions have posted and cleared.
* **hledger-validate-assertions** - Validates account balances against custom
  assert "directives" I include in each journal file.
* **hledger-validate-balances** - Validate that my envelope budget balances
  aren't negative.
* **hledger-validate-dates** - Wrapper for `hledger check ordereddates` to
  validate that journal entries are are in order.
* **hledger-validate-entries** - Validate Budget and Expenses lines on each
  journal entry.
* **hledger-validate-envelopes** - Validate that cash balance and budget balance
  are equal. (This is a shell script that wraps `validate_envelopes.py`.)
* **hledger-validate** - Wrapper that invokes all the other validation scripts.

Some of the above files have required variables that must be set in
`helpers_config.sh` (see below). These are declared with the `required_var`
command in each file as appropriate and will be checked when the command is run.

### Helpers

* **common.sh** - Helper functions for bash scripts.
* **validate_envelopes.py** - Implementation of validate_envelopes' main logic.

## Configuration paths

By default, configuration is sourced from a script called `helpers_config.sh` in
the same directory as the file given by the `LEDGER_FILE` environment variable.
Journal files are expected to be found in a directory named `journals` in the
same directory as the `LEDGER_FILE`. This behavior can be overridden by the
following environment variables:

* `LEDGER_DIR`: By default, this is the directory containing the `LEDGER_FILE`.
* `JOURNALS_DIR`: By default, this is `$LEDGER_DIR/journals`.
* `CONFIG_FILE`: By default, this is `$LEDGER_DIR/helpers_config.sh`.

## Configuration variables

These can be provided in helpers_config.sh or as environment variables. However,
the values are always treated and quoted as arrays, so any values containing
spaces will need to be provided as array entries.

* `REGULAR_ASSET_ACCOUNTS` - Asset accounts to show in the **balances** command.
* `REGULAR_LIABILITY_ACCOUNTS` - Liability accounts to show in the **balances**
  command.
* `EXPENSE_ACCOUNTS` - Accounts to show in the **expenses** command.
* `LOAN_ACCOUNTS` - Accounts to show in the **loan_balances** and
  **loan_progress** commands.
* `POCKET_ACCOUNTS` - Accounts to show in the **pockets** command.
* `CASH_ACCOUNTS` - Real accounts to check against `BUDGET_ACCOUNTS` in the
  **validate_envelopes** command.
* `BUDGET_ACCOUNTS` - Virtual accounts to display in the **envelopes** command
  and to validate in the **validate_envelopes** command.
* `BANKING_BROWSER` - Invocation of the web browser to use in **launch**. Must
  be an array if any flags are provided.
  - e.g. `BANKING_BROWSER=("chromium-browser" "--new-window")`
* `BANKING_SITES` - Array of websites to open when **launch** is run.
* `LEDGER_EDITOR` - The editor to open journals in when **launch** is run. Must
  be an array if any flags are provided.

### Sample configuration

```bash
# ~/ledger/helpers_config.sh
if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
    echo "This is a config file and shouldn't be run directly!" >&2
    exit 1
fi

REGULAR_ASSET_ACCOUNTS=assets
REGULAR_LIABILITY_ACCOUNTS=liabilities
EXPENSE_ACCOUNTS=(expenses liabilities:loans)
LOAN_ACCOUNTS=liabilities:loans
POCKET_ACCOUNTS=budget:buffer
CASH_ACCOUNTS=(assets liabilities:credit)
BUDGET_ACCOUNTS=budget
BANKING_BROWSER=("chromium-browser" "--new-window")
BANKING_SITES=(
  'https://not-a-real.bank'
  'https://another.fake-bank.com'
)
LEDGER_EDITOR=emacs
```

## License

my-hledger Copyright (C) 2019 pushittoprod

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along
with this program.  If not, see <https://www.gnu.org/licenses/>.