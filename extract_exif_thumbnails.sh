#!/bin/bash
set -o nounset -o errexit -o pipefail -o noclobber

# extract_exif_thumbnails.sh
# First written 2020-01-22 by <jonas@jonasjberg.com>
#
# Extracts EXIF thumbnails from one or more given filepaths.
# Extracted thumbnails are written to filenames on the form
# ${ORIGINAL_FILENAME_WITHOUT_EXTENSION}_exif_thumbnail.jpg


_SELF_BASENAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly _SELF_BASENAME


if [ $# -eq 0 ]
then
    command cat <<EOF >&2

    Usage:  $_SELF_BASENAME [FILEPATH]...

    Extracts EXIF thumbnails from one or more given filepaths.
    Extracted thumbnails are written to filenames on the form
    \${ORIGINAL_FILENAME_WITHOUT_EXTENSION}_exif_thumbnail.jpg

    Exit status is 0 if thumbnails was successfully extracted
    from all given filepaths, otherwise 1.

EOF
    exit 1
fi


if ! {
    command -v exif &>/dev/null &&
    command exif --help | command grep -Fq -- '--extract-thumbnail'
}
then
    command cat <<'EOF' >&2

    Required executable "exif" is not available.
    Expected "exif" to be the "command-line front-end to libexif",
    but this does not seem to be the case.. ?

EOF
    exit 127
fi


declare -i exitstatus=0

for arg in "$@"
do
    [ -r "$arg" ] || continue

    filepath="$(command readlink --canonicalize-existing -- "$arg")" || continue
    [ -f "$filepath" ] || continue

    case $(command file --mime-type --brief -- "$filepath") in
        image/jpeg)
            # OK!
            ;;
        *)
            continue
            ;;
    esac

    out_filepath="${filepath%.*}_exif_thumbnail.jpg"
    if [ -e "$out_filepath" ]
    then
        printf '%s: Skipped existing file: %s\n' "$_SELF_BASENAME" "$filepath"
        continue
    fi

    if ! command exif \
        --extract-thumbnail --no-fixup --output="$out_filepath" -- "$filepath"
    then
        exitstatus=1
    fi
done


exit "$exitstatus"
