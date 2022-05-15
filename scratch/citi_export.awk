#!/usr/bin/env awk
# Usage:
#   - export transactions from Citi as a TXT file
#   - reverse the file with tac RAWCITIFILE.TXT > CITIFILE.TXT
#   - update the TXT file as needed to remove already-entered transactions, etc.
#   - awk -f citi_export.awk CITIFILE.TXT >> ~/Documents/ledger/2021/journals/citi/costco.journal
#
# Sample input:
#   \tStatus\t\tDate\t\t\tDescription\t\t\tAmount\t\tMember Name\t
#   \tCleared\t\t05/10/2022\t\tDD DOORDASH DAIRYQUEE 855-973-1040 CA\t\t\t$ 33.29\t\tMY NAME\t
#
# Sample output:
#   2022-05-10 * Doordash | Dairy Queen
#      Liabilities:Credit:Citi:Costco  $-33.29
#      (Budget:Core:Food:Dining Out)  $-33.29
#      Expenses:Core:Food:Dining Out

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

    TODAY = strftime("%Y-%m-%d %H:%M")

    # print a header to separate the entries from the rest of the journal file
    print ""
    print "# Citi export as of " TODAY
}

# reset and initialize variables for every line
{
    category = "!!TODO!!"
    account = "Liabilities:Credit:Citi:Costco"
    description = ""

    date = convert_date($DATE)

    switch ($STATUS) {
        case "Status":
            next
            break
        case "Cleared":
            status = "*"
            break
        default:
            status = "!"
            break
    }

    desc = $DESC
    amount = convert_amount($AMOUNT)
}

## handle common transactions

desc ~ /DOORDASH/ {
    category = "Core:Food:Dining Out"

    gsub(/(DD )?DOORDASH([*] )? /, "", desc)
    gsub(/ WWW.DOORDASH.CA/, "", desc)
    gsub(/ 855-973-1040/, "", desc)
    gsub(/ CA$/, "", desc)

    # Started doing this but maybe using the raw output would be easier
    switch (desc) {
        case /sarku/:
            desc = "Sarku Japan"
            break
        case /dairy/:
            desc = "Dairy Queen"
            break
        case /carls/:
            desc = "Carl's Jr"
            break
        case /7-ELEVEN/:
            desc = "7-Eleven"
            break
        case /TACOBELL/:
            desc = "Taco Bell"
            break
        case /PANDA/:
            desc = "Panda Express"
            break
        case /MCDONALDS/:
            desc = "McDonalds"
            break
        case /WOWBAO/:
            desc = "Wow Bao"
            break
        case /TERIYAKI MAD/:
            desc = "Teriyaki Madness"
            break
        case /QDOBA/:
            desc = "Qdoba"
            break
    }

    desc = "Doordash | " desc
}

desc ~ /INSTANT INK/ {
    desc = "Instant Ink"
    category = "Core:Instant Ink"
}

desc ~ /MEYER/ || desc ~ /INSTACART/ {
    category = "Core:Food:Groceries"
}

desc ~ /APPLE.COM/ && date ~ /-05$/ && amount == "$-4.99" {
    desc = "Apple Arcade"
    category = "Fun:Apple Arcade"
}

desc ~ /IFTTT/ {
    desc = "IFTTT"
    category = "Fun:IFTTT"
}

desc ~ /PLAYSTATIONNETWORK/ && date ~ /-10$/ && amount == "$-4.99" {
    desc = "Playstation Network | EA Play"
    category = "Fun:Media:Games"
}

{
    print ""
    print date " " status " " desc
    print "    " account "  " amount
    print "    (Budget:" category ")  " amount
    print "    Expenses:" category
}
