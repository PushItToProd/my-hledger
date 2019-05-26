# my-hledger

A collection of helper scripts for my hledger setup.

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
based mostly on [YNAB](https://www.youneedabudget.com/the-four-rules/).

## The Scripts

Each script has a prefix of `hledger-`, which allows it to be picked up as an
hledger subcommand if it's on the path.

* **balances** - Displays main asset and liability account balances with a few
  small variations by account type. My bank reflects all pending transactions
  immediately on my checking and savings account balances, but only cleared
  transactions are reflected on credit accounts, so the flags on each category
  are configured to reflect this, allowing me to validate my ledger balances
  against those displayed by my bank.
* **bills** - Checks if transactions matching queries in a config file have been
  made in the current month.
* **envelopes** - Displays balances of envelope budget accounts.
* **expenses** - Summarizes monthly expenditures by expense account.
* **income** - Shows net revenues and expenses by income and expense account by
  month.
* **launch** - Launches a web browser with banking sites and a text editor with
  all journal files open.
* **loan_balances** - Shows current loan balances.
* **loan_progress** - Shows loan balances by month.
* **pockets** - Shows funds in envelopes not marked for specific expenses.
* **validate_dates** - hledger's check-dates chokes if you have multiple files,
  so this iterates over all journal files and checks them individually.
* **validate_envelopes** - Checks whether cash balance and budget balance are
  equal.

Some of the above files have required variables that must be set in
`helpers_config.sh` (see below). These are declared with the `required_var`
command in each file as appropriate and will be checked when the command is run.

### Helpers

* **common.sh** - Helper functions for bash scripts.
* **validate_envelopes.py** - Implementation of validate_envelopes' main logic.
  `validate_envelopes` itself is a bash script that passes the appropriate
  config options to `validate_envelopes.py`.

## Configuration paths

By default, configuration is sourced from a script called `helpers_config.sh` in
the same directory as the file given by the `LEDGER_FILE` environment variable.
Journal files are expected to be found in a directory named `journals` in the
same directory as the `LEDGER_FILE`. This behavior can be overridden by the
following environment variables:

* `LEDGER_DIR`: By default, this is the directory containing the `LEDGER_FILE`.
* `JOURNALS_DIR`: By default, this is `$LEDGER_DIR/journals`.
* `CONFIG_FILE`: By default, this is `$LEDGER_DIR/helpers_config.sh`.

** Configuration variables

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