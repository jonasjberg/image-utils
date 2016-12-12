# Extract images from Android thumbnail cache
# ===========================================
#
# Extract thumbnail cache files usually stored in `DCIM/.thumbnails` or
# similar, either internal storage or SD-card.
#
# Example with Android phone connected with USB via mtp under Linux:
#
# user@host /run/user/1000/gvfs/mtp:host=ID_STRING/PATH/DCIM/.thumbnails
# $ file --mime .thumb*
#
# .thumbdata3-2763608130:   application/octet-stream; charset=binary
# .thumbdata3--2968290308:  application/octet-stream; charset=binary
# .thumbindex3-2763708139:  application/octet-stream; charset=binary
# .thumbindex3--2968290308: application/octet-stream; charset=binary
#
# This script extracts the .thumbdata3-* files.
# Foremost does all the work and must be installed for this to work.

# set -e
# set -x
# shopt -s nullglob


[ -d "$1" ] || { echo "Not a directory: \"${1}\"" ; exit 1 ; }



echo "Now in $(pwd)"
(
echo "Changing directory to "${1}""
cd "$1"

echo "Now in $(pwd)"

# for f in thumb*
# do
#     [ -f "$f" ] || continue
# 
#     # Remove all non-ascii characters for use in destination directory.
#     f_ascii="${f//[^[:ascii:]]/}"
#     dest_dir="$(pwd)/${f_ascii}_foremost"
#     mkdir -vp "$dest_dir"
# 
#     # Run foremost with flags:
#     #   -t all   all file types
#     #   -v       verbose
#     #   -a       all headers
#     #   -d       indirect block detection
#     foremost -t all -v -a -d -o "$dest_dir" -i "$f"
# done
)

# shopt -u nullglob
