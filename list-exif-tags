#!/usr/bin/env bash
#
# list-exif-tags
# ~~~~~~~~~~~~~~
# Written by Jonas Sjöberg
# https://github.com/jonasjberg
# jomeganas@gmail.com
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

#set -x
# TODO: Document properly. Comments.

SCRIPT_NAME="$(basename $0)"


function die()
{
    printf "%s. Exiting ..\n" "${1:-"Unspecified error"}" 2>&1
    exit 1
}


# Recursively search for images with any exif tags (keywords) and print results
# as defined by "printFormat". 
# TODO: WARNING: Uses '¤' as delimiter! 
#                File names containing '¤' will mess up the columns.
function find_images_with_exif_tags()
{
    exiftool -quiet             \
             -ignoreMinorErrors \
             -filename          \
             -recursive         \
             -if "\$keywords"   \
             -printFormat '$directory/$filename ¤ $keywords' "$1"
}


if [ $# -eq 0 ]
then
    TAB='    '
    FORMAT="${TAB}%s\n" 
    printf "%s\n" "USAGE: \"${SCRIPT_NAME} [SEARCH PATH]\""
    printf "$FORMAT" "This program searches [SEARCH PATH] for images with exif tags."
    printf "$FORMAT" "Results are shown with the full path and tags for each file."
fi


path=${1:-}
[ -n "$path" ] || die "Path not specified"
[ -d "$path" ] || die "Invalid path"


find "$path" -mindepth 0 -type d -print | while IFS= read -r dir
do
    [ -d "$dir" ] || continue
    find_images_with_exif_tags "$dir"
done | column -t -s'¤'


exit $?
