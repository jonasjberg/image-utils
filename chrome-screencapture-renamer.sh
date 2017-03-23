#!/usr/bin/env bash

# chrome-screencapture-renamer.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Written in 2016 by Jonas Sjöberg
# https://jonasjberg.github.io/
#
# Renames images created by the "Full Page Screen Capture" Chrome plugin.
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

# set -x

TS_FORMAT='+%FT%H%M%S'
MATCH_PREFIX='screencapture-'
MATCH_EXTENS='png'
ADD_FILETAG='screenshot'
FILETAG_SEP=' -- '
DRYRUN='false'


# The "date" command included with GNU coreutils differs from that shipped with
# MacOS.  Require the GNU version.  (install coreutils through homebrew on mac)
case "$OSTYPE" in
    darwin*) datecmd="$(which gdate)" ;;
    *)       datecmd="$(which date)"  ;;
esac

if ! "$($datecmd --version)" 2>&1 | head -n 1 | grep -q 'GNU coreutils'
then
    echo "This program requires GNU coreutils date to run." 2>&1
    exit 1
fi


if [ ! -d "$1" ]
then
    echo "Usage: $(basename $0) PATH"
    echo "Files in PATH that matches \"${MATCH_PREFIX}*.${MATCH_EXTENS}\" will be renamed."
    exit 1
fi

(
    cd "$1" || { echo "Unable to cd into \"${1}\" .." ; exit 1 ; }

    timestampedfiles=( ${MATCH_PREFIX}*.${MATCH_EXTENS})
    for f in "${timestampedfiles[@]}"
    do
        [ -z "$f" ] && continue
        [ -f "$f" ] || continue

        # Expect 13 digits.
        # Note: Hardcoded leading "1" followed by 12 digits means
        #       dates before 2001-09-09T034640 are ignored.
        ts_digits="$(echo "$f" | grep -oE '1[0-9]{12,12}')"
        [ -z "$ts_digits" ] && continue

        # Get the first 10 of the 13 digits.
        timestamp="$($datecmd --date "@${ts_digits:0:10}" $TS_FORMAT)"

        # Insane sanity check ..
        if ! grep -qoE '^20[01][0-9]-[01][0-9]-[0-3][0-9]T[0-2][0-9][0-5][0-9][0-5][0-9]$' <<< "$timestamp"
        then
            echo "  WARNING  -- Failed sanity check. Skipping .."
            echo "   [FILE] : ${f}"
            echo "   Digits : ${ts_digits}"
            echo ""
            echo ""
            continue
        fi

        # Strip from '-' followed by ts_digits to the end.
        base="${f%-${ts_digits}*}"

        # Assemble new name. Extension is added back.
        # Also removes 'screencapture-' and adds filetag.
        if [ -n "${ADD_FILETAG:-}" ]; then
            tag="${FILETAG_SEP}${ADD_FILETAG}"
            base="${base##${MATCH_PREFIX}}"
        fi

        new_filename="${timestamp} ${base}${tag}.${MATCH_EXTENS}"

        if $DRYRUN; then
            echo "   [FILE] : ${f}"
            echo "   Digits : ${ts_digits}"
            echo "Timestamp : ${timestamp}"
            echo  "[RESULT] : ${new_filename}"
            echo ""
            echo ""
        else
            mv -nvi -- "$f" "$new_filename"
        fi
    done
)
