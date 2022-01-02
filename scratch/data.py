"""
A (WIP) data model for hledger CSV data.
"""
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


