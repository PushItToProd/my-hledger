#!/usr/bin/env python3.11

# This is an optimized version of hledger-bills that will perform all checks in
# pure Python against the output of `hledger print` rather than having to run
# hledger repeatedly for each given bill query.

from datetime import date
import argparse
import csv
import json
import os
import subprocess
import sys


BILL_FILE_NAME = 'bills.py'
EXPECTED_HEADERS = [
    "txnidx", "date", "date2", "status", "code", "description", "comment",
    "account", "amount", "commodity", "credit", "debit", "posting-status",
    "posting-comment"
]


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--period', default=date.today().strftime("%Y-%m"))
    parser.add_argument('-b', '--bill-file')
    return parser


@contextmanager
def run(cmd, shell=None, **kwargs):
    """
    Execute the given command using Popen, with stdout=PIPE and text=True.

    Using Popen instead of subprocess.run() provides a major performance boost,
    since we can process stdout directly without waiting for the command to run
    and its output to be read into a string.
    """
    if shell is None:
        shell = isinstance(cmd, str)
    with Popen(cmd, stdout=PIPE, text=True, shell=shell, **kwargs) as proc:
        try:
            yield proc
        finally:
            try:
                proc.kill()
            except TimeoutExpired:
                proc.wait()


def get_bill_file_path():
    """
    Get the bills file from either the environment variable BILL_FILE_V2 or
    BILL_FILE or by checking for a file named bills.py in LEDGER_FILE.
    """
    bill_file = os.environ.get('BILL_FILE_V2') or os.environ.get('BILL_FILE')
    if bill_file:
        if not bill_file.endswith('.py'):
            raise Exception(
                f"BILL_FILE or BILL_FILE_V2 is set, but the file has an "
                f"invalid extension. It should end with '.py' but instead it's "
                f"set to {bill_file}."
            )
        return bill_file

    # if no explicit path to a bills file exists, figure it out from the
    # LEDGER_FILE path
    ledger_file = os.environ.get('LEDGER_FILE')
    if ledger_file is None:
        raise Exception(
            'Could not find a valid bill file. Set the BILL_FILE or BILL_FILE_v2 '
            'environment variable to a valid file (name must end in ".py") or '
            'create a file named bills.py in the same directory as your '
            'LEDGER_FILE.'
        )

    path = os.path.join(os.path.dirname(ledger_file), BILL_FILE_NAME)
    if not os.path.isfile(path):
        raise Exception(
            f"Could not find a valid bill file. BILL_FILE is not set and "
            f"a file named {BILL_FILE_NAME} could not be found in the same "
            f"directory as {ledger_file}."
        )

    return path


def green(s):
    """
    Wrap a string in ANSI terminal escape codes to make it green.
    """
    return f"\u001b[32m{s}\u001b[0m"


def red(s):
    """
    Wrap a string in ANSI terminal escape codes to make it red.
    """
    return f"\u001b[31m{s}\u001b[0m"


def read_file(file_name):
    with open(file_name) as f:
        return f.read()


def load_bill_rules(rules: str):
    """
    Load a set of rules defined as Python functions from the given string.
    """
    exec_locals = {}
    exec(rules, {}, exec_locals)

    # look for a variable named 'bills'
    bills = exec_locals.get('bills')
    if bills is None:
        raise Exception(
            f"The bill file {bill_file} must contain a variable named "
            f"'bills', but it does not."
        )
    return bills


def iter_transactions_csv(period):
    """
    Iterate over the transactions from hledger print, returning a tuple of
    each transaction's txnidx and its lines from the CSV.
    """
    get_txnidx = lambda t: t['txnidx']
    with run(f"hledger print --output-format=csv --period='{period}'") as proc:
        reader = csv.DictReader(proc.stdout)
        for txnidx, lines in itertools.groupby(reader, key=get_txnidx):
            yield txnidx, list(lines)


def main():
    args = get_parser().parse_args()
    period = args.period
    bill_file = args.bill_file or get_bill_file_path()

    rules_str = read_file(bill_file)
    rules = load_bill_rules(rules_str)
    rule_results = {name: False for name in rules}

    print(f"Bills for period {period}")

    for txnidx, postings in iter_transactions_csv(period):
        for name, rule in rules:
            if rule_results[name]:
                continue
            if rule(postings):
                rule_results[name] = True


if __name__ == '__main__':
    main()
