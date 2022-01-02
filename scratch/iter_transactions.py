#!/usr/bin/env python3.9
import csv
import io
import itertools
import shutil
from subprocess import PIPE, Popen, TimeoutExpired
from contextlib import contextmanager
from dataclasses import dataclass, field, fields


@dataclass
class Line:
    txnidx: str
    date: str
    status: str
    description: str
    account: str
    amount: str
    commodity: str
    raw: dict = field(repr=False)

    @classmethod
    def from_row(cls, row):
        fieldnames = set(f.name for f in fields(cls))
        return cls(
            **{
                k: v for k, v in row.items() if k in fieldnames
            },
            raw=row,
        )


@contextmanager
def run(*args, **kwargs):
    """
    Execute the given command using Popen, with stdout=PIPE and text=True.

    Using Popen instead of subprocess.run() provides a major performance boost,
    since we can process stdout directly without waiting for the command to run
    and its output to be read into a string.
    """
    with Popen(args, stdout=PIPE, text=True, **kwargs) as proc:
        try:
            yield proc
        finally:
            try:
                proc.kill()
            except TimeoutExpired:
                proc.wait()


def hledger_print(*args, **kwargs):
    return run("hledger", "print", "-O", "csv", *args, **kwargs)


def iter_transactions(reader):
    get_key = lambda t: t['txnidx']
    with hledger_print() as proc:
        reader = csv.DictReader(proc.stdout)
        for txnidx, lines in itertools.groupby(reader, key=get_key):
            yield txnidx, lines


def main():
    with hledger_print() as proc:
        buf = proc.stdout
        reader = csv.DictReader(buf)
        for txnidx, lines in iter_transactions(reader):
            print(f"\n=== Transaction {txnidx} ===")
            for line in lines:
                print(line)


if __name__ == '__main__':
    main()
