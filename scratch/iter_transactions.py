#!/usr/bin/env python3.9
import csv
import io
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
    cmd, *cmd_args = args
    if cmd[0] not in ('.', '/'):
        cmd = shutil.which(cmd)
        assert cmd, f"could not find {args[0]} on the path"

    args = (cmd, *cmd_args)

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
    txn = None
    for row in reader:
        if row.txnidx != txn:
            txn = row.txnidx
            print("")
            print(f"=== Transaction {txn} ===")
        print(row)


def main():
    with hledger_print() as proc:
        buf = proc.stdout
        reader = (Line.from_row(r) for r in csv.DictReader(buf))
        iter_transactions(reader)


if __name__ == '__main__':
    main()
