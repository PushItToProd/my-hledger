#!/usr/bin/env python3.7
"""
Check whether budget and actual account balances match.
"""
import argparse
import csv
import decimal
import io
import re
import subprocess
import sys


# Used to strip non-numeric characters that break Python's decimal parsing.
NON_NUMERIC_CHARS = re.compile('[^0-9-.]')


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cash-accounts', nargs='+')
    parser.add_argument('--budget-accounts', nargs='+')
    return parser


def hledger_decimal(n):
    """
    Convert an hledger dollar amount to a Decimal. NON_NUMERIC_CHARS is used to
    preprocess the hledger string value by removing non-numeric characters.
    """
    stripped = re.sub(NON_NUMERIC_CHARS, '', n)
    return decimal.Decimal(stripped)


def run(cmd):
    """
    Wrapper for subprocess.run that sets some default parameters.
    """
    return subprocess.run(cmd, stdout=subprocess.PIPE,
                          universal_newlines=True).stdout


def parse_csv(s):
    """
    Parse a string as CSV, returning a CSV reader object.
    """
    buf = io.StringIO(s)
    return csv.reader(buf)


def get_hledger_total(cmd, query, total_row):
    flags = "-UPC -O csv -V".split()
    output = run(["hledger", cmd, *query, *flags])
    reader = parse_csv(output)
    _, total = next(row for row in reader if row[0] == total_row)
    return hledger_decimal(total)


def get_net_balance(accounts):
    """
    Get the total balance of cash accounts.
    """
    return get_hledger_total("bs", accounts, "Net:")


def get_envelope_balance(accounts):
    """
    Get the total balance of envelope budget accounts.
    """
    return get_hledger_total("bal", accounts, "total")


def main():
    args = get_parser().parse_args()
    net = get_net_balance(args.cash_accounts)
    envelope = get_envelope_balance(args.budget_accounts)

    if net != envelope:
        print("Budget and actual balances do not match!", file=sys.stderr)
        print(f"Budget balance: {envelope}")
        print(f"Actual balance: {net}")
        sys.exit(1)

    print("Balances match")


if __name__ == "__main__":
    main()
