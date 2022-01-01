#!/usr/bin/env python3.9
import csv
import io
import subprocess
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


def run(*cmd, **kwargs):
    """
    Wrapper for subprocess.run that sets some default parameters.
    """
    return subprocess.run(
        cmd,
        capture_output=True,
        universal_newlines=True,
        **kwargs
    )


def main():
    # FIXME: don't include -p lastweek here
    proc = run("hledger", "print", "-p", "lastweek", "-O", "csv")
    buf = io.StringIO(proc.stdout)
    reader = (Line.from_row(r) for r in csv.DictReader(buf))

    txn = None
    for row in reader:
        if row.txnidx != txn:
            txn = row.txnidx
            print("")
            print(f"=== Transaction {txn} ===")
        print(row)


if __name__ == '__main__':
    main()
