from iter_transactions import iter_transactions, print_transaction


def negate(amount):
    """
    >>> negate('$100.00')
    '$-100.00'
    >>> negate('$-100.00')
    '$100.00'
    """
    if amount.startswith('$-'):
        return '$' + amount[2:]
    else:
        return '$-' + amount[1:]


def validate_transaction(lines):
    expenses = {}
    budgets = {}
    for line in lines:
        account = line['account']
        amount = line['amount']
        if account.startswith('(Budget:'):
            if account[-1] != ')':
                yield f"Missing ')' for account '{account}'"


def main():
    for txnidx, lines in iter_transactions():
        errs = list(validate_transaction(lines))
        if not errs:
            continue
        print("\nErrors found for transaction!\n")
        print_transaction(lines)
        print("\nErrors:")
        for err in errs:
            print(" *", err)


if __name__ == '__main__':
    main()
