#!/usr/bin/env bash

# rename-receipts.sh
# ~~~~~~~~~~~~~~~~~~
# Written in 2017 by Jonas Sjöberg
# http://www.jonasjberg.com
# https://github.com/jonasjberg
# ______________________________________________________________________________
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ______________________________________________________________________________


assert_program_available()
{
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Please install \"$1\" before running this script." 1>&2
        exit 1
    fi
}

main()
{
    local arg_basename="$(basename "$1")"
    local arg_extension="${arg_basename##*.}"

    echo "Processing \"${1}\" .."
    ocrtextfile="${WORKDIR}/${arg_basename%.*}.txt"
    # echo "ocr text file: \"${ocrtextfile}\""

    pytesseract -l swe "$1" > "$ocrtextfile"

    if [ ! -f "$ocrtextfile" ] || [ ! -s "$ocrtextfile" ]
    then
        # echo "OCR failed for \"${arg_basename}\""
        return 1
    fi

    # Try to populate these fields:
    unset arg_date
    unset arg_store
    unset arg_price

    #   Get the date and time.
    #   ----------------------
    #   Attempt/method #1:
    try_datetime_regex '[0-9]{4}.[0-9]{2}.[0-9]{2} [0-9]{2}.[0-9]{2}.[0-9]{2}'
    try_datetime_regex '2017.*(1[0-2]|0[1-9]).*(0[0-9]|1[0-9]|2[0-9]|3[0-1]).*(0[0-9]|1[0-9]|2[0-4]).*[0-5][0-9].*[0-5][0-9]'

    #   Attempt/method #2:
    #   (get only date)
    try_date_regex '2017-(1[0-2]|0[1-9])-(0[0-9]|1[0-9]|2[0-9]|3[0-1])'
    try_date_regex '2017.(1[0-2]|0[1-9]).(0[0-9]|1[0-9]|2[0-9]|3[0-1])'
    try_date_regex '2017.{,2}(1[0-2]|0[1-9]).{,2}(0[0-9]|1[0-9]|2[0-9]|3[0-1])'


    #   Get the store/retailer/seller name.
    #   -----------------------------------
    #   Attempt/method #1:
    try_match_store 'Apoteket Hjartat'    'Apotek Hjärtat'
    try_match_store 'Apoteket Hjartat'    'apotekhjartat'
    try_match_store 'Kronans Droghandel'  'Kronans Apotek'
    try_match_store 'Kronans Droghandel'  'Kronans Droghandel'
    try_match_store 'Kronans Droghandel'  'Kr.*ns Droghandel'
    try_match_store 'Kronans Droghandel'  'kronansapotek'
    try_match_store 'Kronans Droghandel'  'www\.kr.*ek\.se'
    try_match_store 'Coop Konsum Krysset' 'COOP KONSUM KRYSSET'
    try_match_store 'Coop Konsum Krysset' 'KRYSSET'
    try_match_store 'Coop Konsum Krysset' '0107475230'
    try_match_store 'Coop Konsum Hallen'  '0107475260'
    try_match_store 'Coop Konsum Hallen'  'Konsum Hallen'
    try_match_store 'Coop Konsum'         '785000.1517'
    try_match_store 'Coop Konsum'         'COOP'
    try_match_store 'Coop Konsum'         'coop'
    try_match_store 'Tempo Tvargatan'     'Tempo Tvärgatan'
    try_match_store 'Soders Zoo'          '558212.*9030$'
    try_match_store 'Soders Zoo'          '026.81.?18.?73'
    try_match_store 'Soders Zoo'          '556212.9030'
    try_match_store 'Soders Zoo'          '15585846.361317'

    
    #   Get the total cost/price.
    #   Attempt/method #1:
    try_price_regex 'K.RTK.P [0-9]+[\.,][0-9]+'
    try_price_regex 'Belopp: SEK [0-9]+[\.,][0-9]+'
    try_price_regex 'SUMMA: [0-9]+[\.,][0-9]+\ ?(kr)?^'
    try_price_regex 'Total kr [0-9]+[\.,][0-9]+'
    try_price_regex 'Kreditkort .[0-9]+[\.,][0-9]+'
    try_price_regex '[a-zA-Z]{3} [a-zA-Z]{6} [a-zA-Z]{3} \( ... [a-zA-Z]{8} \) [0-9]+[\.,][0-9]+'
    
    [ -z "$arg_date"  ] && arg_date="UNKNOWN_DATE"
    [ -z "$arg_store" ] && arg_store="UNKNOWN_STORE"
    [ -z "$arg_price" ] && arg_price="UNKNOWN_PRICE" || arg_price="${arg_price}kr"

    new_name="${arg_date} ${arg_store} - ${arg_price}.${arg_extension}"
    echo "Result for file: \"${arg_basename}\": \"${new_name}\""

    mv -nv -- "$1" "$new_name"
}

# Greps "$ocrtextfile" with the provided pattern.
# Returns at once if "$arg_date" is already defined.
try_datetime_regex()
{
    [ -n "$arg_date" ] && return

    local _tmp_datetime="$(grep -oE "$1" "$ocrtextfile" | head -n 1)"
    if [ -n "$_tmp_datetime" ]
    then
        echo "Found datetime with regex: \"${1}\""

        # Remove all chars except digits, dashes, spaces and colons.
        _tmp_datetime="${_date_full//[^0-9]/}"
        # echo "Halfway Cleaned up date: \"${_tmp_date_full}\""

        if [ -n "$_tmp_datetime" ]
        then
            # Add dashes and underlines at set positions.
            # Dashes at indices 5 and 8. The letter "T" at index 11.
            # For a final result like: 2017-03-31T215735
            arg_date="$(echo "$_tmp_datetime" | sed 's/./-&/5' | sed 's/./-&/8' | sed 's/./T&/11')"

            return 0
        fi
    fi

    return 1
}

# Greps "$ocrtextfile" with the provided pattern.
# Returns at once if "$arg_date" is already defined.
try_date_regex()
{
    [ -n "$arg_date" ] && return

    local _tmp_date="$(grep -oE -m 1 "$1" "$ocrtextfile")"
    echo "_tmp_date: \"${_tmp_date}\""

    if [ -n "$_tmp_date" ]
    then
        echo "Found date with regex: \"${1}\""
        # Remove all chars except digits, dashes, spaces and colons.
        _tmp_date="${_tmp_date//[^0-9]/}"

        if [ -n "$_tmp_date" ]
        then
            # Add dashes and underlines at set positions.
            # Dashes at indices 5 and 8.
            # For a final result like: 2017-03-31
            _tmp_date="$(echo "$_tmp_date" | sed 's/./-&/5' | sed 's/./-&/8')"

            arg_date="${_tmp_date}Thhmmss"
            return 0
        fi
    fi

    return 1
}

# Greps "$ocrtextfile" with the provided pattern.
# Returns at once if "$arg_price" is already defined.
try_price_regex()
{
    [ -n "$arg_price" ] && return

    _tmp_price="$(grep -oE "$1" "$ocrtextfile")"
    if [ -n "$_tmp_price" ]
    then
        # echo "Found price with regex: \"${1}\""
        arg_price="${_tmp_price//[^0-9\.,]/}"
        arg_price="${arg_price//,/\.}"
        # echo "Price: \"${arg_price}\""
        return 0
    else
        return 1
    fi
}

# Greps "$ocrtextfile" with the provided pattern.
# Returns at once if "$arg_store" is already defined.
try_match_store()
{
    [ -n "$arg_store" ] && return

    if grep -qoE "$2" < "$ocrtextfile"
    then
        # echo "Matches store: \"$1\""
        arg_store="$1"
        return 0
    else
        return 1
    fi
}


# Make sure dependencies are installed.
assert_program_available pytesseract


# Get absolute path to script working directory, readlink handles symlinks.
# From the readlink GNU coreutils 8.25 version manpage:
#
#   -f, --canonicalize  canonicalize by following every symlink in every
#                       component of the given name recursively; all but the
#                       last component must exist
#
SCRIPTPATH=("$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd)")


# Create temporary working directory within the script directory.
WORKDIR="$(mktemp -d -p "$SCRIPTPATH")"

if [ ! -d "$WORKDIR" ]
then
    echo "Unable to create working directory. Aborting." 1>&2
    exit 1
fi

# echo "SCRIPTPATH: \"${SCRIPTPATH}\""
# echo "   WORKDIR: \"${WORKDIR}\""


# Check provided arguments.
if [ "$#" -eq 0 ]
then
    echo "USAGE: \"$(basename $0) [FILE]...\""
    echo ""
    echo "Where [FILE] is one or more images readable by pytesseract."
    exit 1
fi

# Enter main loop and iterate over arguments.
for arg in "$@"
do
    if [ ! -f "$arg" ]
    then
        echo "Not a file: \"${arg}\""
        continue
    elif [ ! -r "$arg" ]
    then
        echo "Not a readable file: \"${arg}\""
        continue
    else
        case $(file --mime-type --brief -- "$arg") in
            image/*)  main "$arg" ;;
                  *) { echo "Not an image: \"${arg}\"" ; continue ; } ;;
        esac
    fi
done


exit $?


