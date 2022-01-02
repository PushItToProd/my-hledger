#!/usr/bin/env python3.9
import csv
import io
import itertools
import shutil
from subprocess import PIPE, Popen, TimeoutExpired
from contextlib import contextmanager


@contextmanager
def run(cmd, shell=True, **kwargs):
    """
    Execute the given command using Popen, with stdout=PIPE and text=True.

    Using Popen instead of subprocess.run() provides a major performance boost,
    since we can process stdout directly without waiting for the command to run
    and its output to be read into a string.
    """
    with Popen(cmd, stdout=PIPE, text=True, shell=shell, **kwargs) as proc:
        try:
            yield proc
        finally:
            try:
                proc.kill()
            except TimeoutExpired:
                proc.wait()


def iter_transactions():
    """
    Iterate over the transactions from hledger_print(), returning a tuple of
    each transaction's txnidx and its lines from the CSV.
    """
    get_key = lambda t: t['txnidx']
    with run("hledger print -O csv") as proc:
        reader = csv.DictReader(proc.stdout)
        for txnidx, lines in itertools.groupby(reader, key=get_key):
            yield txnidx, list(lines)


def print_transaction(lines):
    line = lines[0]
    date = line['date']
    status = line['status']
    description = line['description']
    print(f"{date} {status} {description}")
    if comment := line['comment']:
        print("    ;", comment)
    for line in lines:
        amount = line['amount']
        commodity = line['commodity']
        if commodity == '$':
            amount = commodity + amount
        else:
            amount = amount + ' ' + commodity
        line_status = line['posting-status']
        if line_status:
            line_status += ' '
        account = line['account']
        comment = line['posting-comment']
        if comment:
            comment = " ; " + comment

        print(f"    {account:38} {amount:>9}{comment}")


def main():
    for txnidx, lines in iter_transactions():
        print("")
        print_transaction(lines)


if __name__ == '__main__':
    main()
