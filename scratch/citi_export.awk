#!/usr/bin/env awk
# Usage:
#   - export transactions from Citi as a TXT file
#   - reverse the file with tac RAWCITIFILE.TXT > CITIFILE.TXT
#   - update the TXT file as needed to remove already-entered transactions, etc.
#   - awk -f citi_export.awk CITIFILE.TXT >> ~/Documents/ledger/2021/journals/citi/costco.journal

function trim_str(str)
{
    gsub(/(^[[:space:]]+|[[:space:]]+$)/, "", str)
    return str
}

function convert_date(date,
    # function locals
    _year, _month, _day)
{
    split(date, d, "/")
    _year = d[3]
    _month = d[1]
    _day = d[2]
    return _year "-" _month "-" _day
}

function convert_amount(amount)
{
    split(amount, aparts, " ")
    if (aparts[1] == "$")
        amount = "$-" aparts[2]
    else
        amount = "$" aparts[2]
    return amount
}

# constants
BEGIN {
    FS = "\t+"
    IGNORECASE = 1

    # 1 is empty due to a leading tab
    STATUS = 2
    DATE = 3
    DESC = 4
    AMOUNT = 5
    NAME = 6     # not used but here for documentation purposes

    print "# Citi export as of "
}

# loop variables
{
    category = "!!TODO!!"
    account = "Liabilities:Credit:Citi:Costco"
    description = ""
}


## status

# skip the header line
$STATUS == "Status" {
    next
}

$STATUS == "Cleared" {
    status = "*"
}

$STATUS != "Cleared" {
    status = "!"
}

## set up desc and amount

{
    desc = $DESC
    amount = convert_amount($AMOUNT)
}

## determine category


desc ~ /DOORDASH/ {
    category = "Core:Food:Dining Out"

    gsub(/(DD )?DOORDASH([*] )? /, "", desc)
    gsub(/ WWW.DOORDASH.CA/, "", desc)
    gsub(/ 855-973-1040/, "", desc)
    gsub(/ CA$/, "", desc)

    # Started doing this but I think using the raw output is easier
    # switch (desc) {
    #     case /sarku/:
    #         desc = "Sarku Japan"
    #         break
    #     case /dairy/:
    #         desc = "Dairy Queen"
    #         break
    #     case /carls/:
    #         desc = "Carl's Jr"
    #         break
    #     case /7-ELEVEN/:
    #         desc = "7-Eleven"
    #         break
    #     case /TACOBELL/:
    #         desc = "Taco Bell"
    #         break
    #     case /PANDA/:
    #         desc = "Panda Express"
    #         break
    #     case /MCDONALDS/:
    #     case /WOWBAO/:
    #     case /TERIYAKI MAD/:
    #     case /QDOBA/:
    #     case
    # }

    desc = "Doordash | " desc
}

desc ~ /INSTANT INK/ {
    desc = "Instant Ink"
    category = "Core:Instant Ink"
}

desc ~ /MEYER/ || desc ~ /INSTACART/ {
    category = "Core:Food:Groceries"
}

{
    date = convert_date($DATE)
    print ""
    print date " " status " " desc
    print "    " account "  " amount
    print "    (Budget:" category ")  " amount
    print "    Expenses:" category
}