#!/usr/bin/env bash

# Copyright (c) 2018 jonasjberg
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2.
# See http://www.wtfpl.net/ for more details.

set -o noclobber -o nounset -o pipefail -o errexit


SELF_BASENAME="$(basename "$0")"


assert_has_command()
{
    if ! command -v "$1" >/dev/null 2>&1
    then
        cat >&2 <<EOF

[ERROR] The executable "${1}" is not available on this system.
        Please install "${1}" before running this script.


EOF
        exit 1
    fi
}

print_usage()
{
    fold -s -w 70 <<EOF

Usage:  ${SELF_BASENAME} [TARGET_EXTENSION] [FILES..]

Converts images from one format to another while keeping any metadata.
Given [FILES] are converted the format specified by [TARGET_EXTENSION]

After converting the image, metadata from the original is applied to the target image. The destination image metadata may contain duplicates, but metadata is not likely lost in the conversion.
Tranferring the original metadata in an exact form is probably a non-trivial task..

    [TARGET_EXTENSION]
        See "convert -list format" for valid extensions.

    [FILES..]
        Path(s) to the images to convert.


${SELF_BASENAME} is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2. See http://www.wtfpl.net/ for more details.
${SELF_BASENAME} is distributed WITHOUT ANY WARRANTY.

EOF

}

convert_keep_metadata()
{
    local -r _dest_ext="$1"
    local -r _source_path="$2"

    _dest_path="${_source_path%.*}.${_dest_ext}"
    if [ -e "$_dest_path" ]
    then
        printf '[SKIPPED] Destination exists:  "%s"\n' "$_dest_path"
        return 1
    fi
    # printf 'Converting  "%s"\n       -->  "%s"\n' "$_source_path" "$_dest_path"

    # NOTE: This also transfers metadata but some fields are "translated".
    # For instance; 'Date/Time Original' becomes 'Exif Date Time Original' ..
    if convert -quiet "$_source_path" "$_dest_path"
    then
        if exiftool -quiet -tagsfromfile "$_source_path" "$_dest_path"
        then
            # TODO: Delete original?
            return 0
        fi
    fi

    return 1
}


# Make sure required executables are available.
assert_has_command convert
assert_has_command file
assert_has_command exiftool
assert_has_command mogrify

# Expect at least two arguments.
if [ "$#" -lt "2" ]
then
    print_usage
    exit 0
fi


declare -r target_extension="$1"
shift


for arg in "$@"
do
    if [ ! -f "$arg" ]
    then
        printf '[SKIPPED] Not a file:  "%s"\n' "$arg"
        continue
    elif [ ! -r "$arg" ]
    then
        printf '[SKIPPED] Not a readable file:  "%s"\n' "$arg"
        continue
    else
        case $(file --mime-type --brief -- "$arg") in
            image/*) convert_keep_metadata "$target_extension" "$arg" ;;
                  *) printf '[SKIPPED] Not an image:  "%s"\n' "$arg"
                     continue ;;
        esac
    fi
done


exit $?
