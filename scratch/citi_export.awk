#!/usr/bin/env awk
# GNU Awk script for translating Citi TXT exports to hledger journal entries.
#
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
#
# Test invocation:
#    awk -f scratch/citi_export.awk _scratch/citi_monthtodate.txt | less

# convert date from MM/DD/YYYY to YYYY-MM-DD.
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

# convert citi's amount representation to hledger's.
#
# citi represents debits as "$ 1.23" and credits as "-$ 1.23", while in hledger
# these translate to "$-1.23" and "$1.23"
function convert_amount(amount, _aparts)
{
    split(amount, _aparts, " ")
    if (_aparts[1] == "$") {
        amount = "$-" _aparts[2]
    } else {
        amount = "$" _aparts[2]
    }
    return amount
}

# constants
BEGIN {
    FS = "\t+"
    IGNORECASE = 1

    # field names
    # field 1 is empty due to a leading tab, so we omit it
    STATUS = 2
    DATE = 3
    DESC = 4
    AMOUNT = 5
    NAME = 6     # name isn't used but is here for the sake of completeness
}

# print header to separate the generated journal entries from the previous
# entries in the file
BEGIN {
    TODAY = strftime("%Y-%m-%d %H:%M")

    # print a header to separate the entries from the rest of the journal file
    print ""
    print "# Citi export generated " TODAY
}

# skip the header line and blank lines
$STATUS == "Status" || $STATUS == "" {
    next
}

# reset and initialize variables for every line
{
    category = "!!TODO!!"
    account = "Liabilities:Credit:Citi:Costco"
    description = ""

    date = convert_date($DATE)

    if ($STATUS == "Cleared") {
        status = "*"
    } else {
        status = "!"
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

# print journal line with proper padding and indentation
function print_line(account, amount, linelen) {
    if (!amount) {
        print "    " account
        return
    }
    if (!linelen) linelen = 48
    linelen = linelen - length(account) - 2
    printf("    %s  %" linelen "s\n", account, amount)
}

# print the hledger journal entry
{
    print ""
    print date " " status " " desc
    print_line(account, amount)
    print_line("(Budget:" category ")", amount)
    print_line("Expenses:" category)
}
