from iter_transactions import iter_transactions, print_transaction


def negate(amount):
    """
    >>> negate('100.00')
    '-100.00'
    >>> negate('-100.00')
    '100.00'
    """
    if amount.startswith('-'):
        return amount[1:]
    else:
        return '-' + amount


def validate_transaction(lines):
    expenses = {}
    budgets = {}
    try:
        for line in lines:
            account = line['account']
            amount = line['amount']
            if account.startswith('(Budget:'):
                if account[-1] != ')':
                    yield f"Missing ')' for account '{account}'"
                    # add the missing paren for ease of use
                    account += ')'
                expense_account = 'Expenses:' + account[8:-1]
                if expense_amount := expenses.get(expense_account):
                    if negate(expense_amount) != amount:
                        yield f"Mismatched budget amount for {expense_account}"
                    del expenses[expense_account]
                else:
                    budgets[account[1:-1]] = amount
            elif account.startswith('Expenses:'):
                budget_account = 'Budget:' + account[9:]
                if budget_amount := budgets.get(budget_account):
                    if negate(budget_amount) != amount:
                        yield f"Mismatched budget amount for {account}"
                    del budgets[budget_account]
                else:
                    expenses[account] = amount
    except:
        print("Error processing transaction")
        print_transaction(lines)
        raise

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
