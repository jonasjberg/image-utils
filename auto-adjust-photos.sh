#!/usr/bin/env bash
#
# auto-adjust-photos
# ~~~~~~~~~~~~~~~~~~
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

set -o noclobber -o nounset -o pipefail
# set -x

SCRIPT_NAME="$(basename "$0")"

C_NORMAL="$(tput sgr0)"
C_RED="$(tput setaf 1)"
C_GREEN="$(tput setaf 2)"
C_YELLOW="$(tput setaf 3)"
C_BLUE="$(tput setaf 4)"
C_MAGENTA="$(tput setaf 5)"
C_CYAN="$(tput setaf 6)"
HALFTAB='  '
FULLTAB='    '

# Max image size in bytes. Images under this threshold will be ignored.
MAX_IMAGE_FILE_SIZE=2500000

# FUNCTION MSG_TYPE() -- Prints timestamped debug messages
# Messages can be of three different types (severity): ERROR, INFO and WARNING.
# Usage: msg_type info example informative text
#        msg_type warn some unexpected thing happened
#        msg_type "just text, no type specified"
msg_type()
{
    if [ "$#" -gt "1" ]
    then
        local type="$1"
        shift
    fi

    local text="${@}"
    local label=''

    if [ "$type" == "debug" ] && [ "$verbose" -lt "2" ]
    then
        return
    fi

    case "$type" in
        error ) label="ERROR"
                color="$C_RED"    ;;
        info  ) label="status"
                color="$C_GREEN"  ;;
        warn  ) label="warning"
                color="$C_YELLOW" ;;
        debug ) label="debug"
                color="$C_NORMAL" ;;
        ok    ) label='OK!'
                color="$C_GREEN"  ;;
        *     ) color="$C_NORMAL" ;;
    esac

    # Surround label with brackets if not empty.
    if [ ! -z "$label" ]
    then
        label="[${color}${label}${C_NORMAL}]"
    fi

    printf "${label}${HALFTAB}%s\n" "$text"
}

# Terminates the program. Prints debug information if enabled.
# Takes the exit code as argument. Defaults to 1 if unspecified.
exit_with_status_code()
{
    TIMESTAMP="$(date +%F\ %H:%M:%S)"
    status="${1:-1}"
    msg_type debug "${TIMESTAMP} ${SCRIPT_NAME} exiting with status [${status}]"
    exit "$status"
}

# Displays the usage information.
print_help()
{
    msg_type info "\"${SCRIPT_NAME}\" -- Jonas Sjoberg 2016"
    msg_type info "Auto-adjusts images based on metadata, file size and image dimensions."
    msg_type info "Originally written for automatically modifying images uploaded to the 'Camera Uploads' Dropbox folder."
    msg_type info "Reads file type from magic header bytes, file extension should not matter."
    msg_type usage ""
    msg_type usage "usage: ${SCRIPT_NAME} [options] [file(s)]"
    msg_type usage "options:    -b   brief mode, prints less output"
    msg_type usage "            -d   dry run, simulates what would happen"
    msg_type usage "            -h   display help and usage information"
    msg_type usage "            -v   increase verbosity, prints more debug information"
}


assert_command_available()
{
    if ! command -v "$1" >/dev/null 2>&1
    then
        msg_type error "Missing required executable \"${1}\" .. Aborting."
        exit_with_status_code 127
    fi
}


# Main logic starts from this function which takes a single file as argument.
# Return values:    0 - success, image processed ok
#                   1 - failure, image processing failed
#                   2 - skip, image skipped
main()
{
    local _image="$1"
    msg_type info "Got image file \"${_image}\""

    # What is to be done to the image is determined by the device/camera model.
    # Example: Photos taken with the OnePlus X camera app are very big and blurry
    #          and take up way too much disk space.
    # First try to extract the model using exiftool, then process image based on
    # results. If the model cannot be determined, proceed with checking the ratio
    # of size to disk space usage.
    unset model_result
    model_result="$(exiftool -if '$model' -quiet -s3 -model "${_image}" 2>/dev/null)"
    model_check_exit_code="$?"

    # TODO: Really bail if check fails?
    if [ "$model_check_exit_code" -ne "0" ]
    then
        msg_type error "Camera/device model check failed"
        return 1
    fi

    if [ -z "$model_result" ]
    then
        msg_type warn "Behaviour for unspecified/NULL model not implemented yet. Skipping .."
        return 2
    else
        case "$model_result" in
            "iPhone 4")   model=iphone4       ;;
            "GT-I9100")   model=galaxys4      ;;
            "ONE E1003")  model=oneplusx      ;;
            "DMC-FZ200")  model=compactsystem ;;
            *)            model=unknown       ;;
        esac
    fi

    msg_type debug "Camera/device model: \"${model}\" (\"${model_result}\")"

    local _retcode
    if [ "$model" == 'oneplusx' ]
    then
        downsample_image_if_size_above_threshold "${_image}" '2500000' '75%' '85'
        _retcode="$?"
    elif [ "$model" == 'compactsystem' ]
    then
        if downsample_image_if_size_above_threshold "${_image}" '3500000' '50%' '90'
        then
            auto_orient_from_exif "${_image}"
            _retcode="$?"
        else
            _retcode=1
        fi
    elif [ "$model" == 'galaxys4' ]
    then
        # TODO: Implement device specific behaviours
        msg_type warn 'Behaviour for device not implemented. Skipping ..'
        _retcode=2
    elif [ "$model" == 'iphone4' ]
    then
        # TODO: Implement device specific behaviours
        msg_type warn 'Behaviour for device not implemented. Skipping ..'
        _retcode=2
    elif [ "$model" == 'unknown' ]
    then
        # TODO: Implement device specific behaviours
        msg_type warn "Behaviour for model \"${model}\" (\"${model_result}\") not implemented. Skipping .."
        _retcode=2
    fi

    return "${_retcode}"
}


# Arguments:
#
#   $1: Path to the image file test.
#   $2: Threshold file size in bytes.
#   $3: Resize scale for images whose size exceeds "threshold".
#   $4: Conversion quality for images whose size exceeds "threshold".
#
# Downsamples images whose file size exceed "threshold".
downsample_image_if_size_above_threshold()
{
    local _image="$1"
    local _threshold="$2"
    local _scale="$3"
    local _quality="$4"

    msg_type debug "Checking size of file: \"${_image}\""
    image_size="$(stat -c%s "${_image}")"

    # Compare image size to max size threshold and proceed if size exceeds threshold.
    if [ "$image_size" -gt "${_threshold}" ]
    then
        msg_type debug "Size exceeds threshold (${image_size} > ${_threshold})"
        downsample_image_with_mogrify "${_image}" "${_scale}" "${_quality}"
        # Alternatively: downsample_image_with_aaphoto "$1"

        if [ "$?" -eq "0" ]
        then
            image_size_new="$(stat -c%s "${_image}")"
            percentage="$(echo "scale=2; ($image_size_new - $image_size)/$image_size * 100" | bc)"
            msg_type stats "$(printf "Size (bytes)  was: %12.12s\n" "$image_size")"
            msg_type stats "$(printf "              now: %12.12s     (%-6.6s%% change)\n" "$image_size_new" "$percentage")"
            return 0
        else
            msg_type error "Failed processing \"${_image}\""
            return 1
        fi
    else
        msg_type debug "Size does not exceed threshold (${image_size} < ${_threshold})"
        return 0
    fi
}

downsample_image_with_mogrify()
{
    local _image="$1"
    local _scale="$2"
    local _quality="$3"

    MOGRIFY_OPTS="-scale ${_scale} -quality ${_quality}"
    msg_type info "Downsampling image with mogrify using options \"${MOGRIFY_OPTS}\""
    [ "$dryrun" -eq "1" ] && return
    mogrify ${MOGRIFY_OPTS} "${_image}"
}

downsample_image_with_aaphoto()
{
    AAPHOTO_OPTS='--autoadjust --resize75% --quality85 --overwrite'
    msg_type info "Downsampling image with aaphoto using options \"${AAPHOTO_OPTS}\""
    [ $dryrun -eq 1 ] && return
    aaphoto ${AAPHOTO_OPTS} "$1"
}

auto_orient_from_exif()
{
    local _image="$1"
    local _orientation

    _orientation="$(jhead -v "${_image}" \
                    | sed -nr "s:.*Orientation = ([0-9]+).*:\1:p" \
                    | head -n 1)"

    if [ -z "${_orientation}" ]
    then
        _orientation=0
    fi

    if [ "${_orientation}" -gt "1" ]
    then
        msg_type info "Auto-orienting \"${_image}\" .."
        # mogrify -auto-orient "${_image}"
        # return "$?"
        # TODO: Make sure this does the "right thing" ..
        msg_type info "WOULD HAVE executed: \"mogrify -auto-orient \"${_image}\"\""
    fi

    return 0
}

print_line()
{
    MAX_WIDTH=60
    printf "%-${MAX_WIDTH}.${MAX_WIDTH}s\n" "$*"
}

add_to_total_preprocessed_disk_usage()
{
    #amount=
    total_preprocessed_disk_usage=$(( $total_preprocessed_disk_usage + amount ))
}


# ______________________________________________________________________________
# MAIN ROUTINE EXECUTION STARTS HERE

# Set default options.
verbose=1
brief=0
dryrun=0

# Log program invocation.
TIMESTAMP="$(date +%F\ %H:%M:%S)"
msg_type debug "${TIMESTAMP} starting ${SCRIPT_NAME}"

assert_command_available exiftool
assert_command_available mogrify
assert_command_available convert
assert_command_available aaphoto
assert_command_available jhead


if [ "$#" -eq "0" ]
then
    # No arguments provided.
    msg_type warn "No arguments provided."
    msg_type warn "For help run: \"${SCRIPT_NAME} -h\""
    exit_with_status_code 1
else
    # Parse arguments.
    while getopts bdhv var
    do
        case "$var" in
            b) brief=1                 ;;
            d) dryrun=1                ;;
            h) print_help              ;
               exit_with_status_code 0 ;;
            v) verbose=2               ;;
        esac
    done
    shift $(( $OPTIND - 1 ))

    # Set up counter variables.
    count_total=0
    count_images=0
    count_image_passed=0
    count_image_failed=0

    # Set up global statistics variables.
    total_preprocessed_disk_usage=0

    # Print startup information
    TIMESTAMP="$(date +%F\ %H:%M:%S)"
    msg_type debug "${TIMESTAMP} ${SCRIPT_NAME} is starting."

    # Start iteration over arguments.
    for arg in "$@"
    do
        count_total=$(( $count_total + 1))

        msg_type debug "Checking file MIME type from magic header bytes"
        unset arg_mime
        case $(file --mime-type --brief -- "$arg") in
            image/j*g)  arg_mime=jpg ;;
            image/png)  arg_mime=png ;;
            *)                       ;;
        esac

        if [ -n "$arg_mime" ]
        then
            msg_type debug "File MIME type: ${arg_mime}"
            count_images=$(( $count_images + 1 ))
        else
            msg_type warn "Not an image: \"${arg}\""
            continue
        fi

        main "$arg"
        status="$?"

        if [ $status -eq "2" ]
        then
            msg_type warn "Skipped \"${arg}\" .."
        elif [ $status -eq "1" ]
        then
            count_image_failed=$(( $count_image_failed + 1 ))
        elif [ $status -eq "0" ]
        then
            count_image_passed=$(( $count_image_passed + 1 ))
        fi

        # Extra newline for readability ONLY if brief mode is disabled.
        [ "$brief" -eq "0" ] && printf "\n"
    done

    # Print results with a summary of all tests, *IF* option brief is not set.
    # Keep text width below 60 columns to avoid messy output in small terminal windows.
    if [ $brief -ne "1" ]
    then
        TAB='    '
        SEP=':'
        FORMAT_COL="%-22.22s ${SEP} %-35.35s\n"
        print_line ""
        print_line ""
        print_line "Summary report"
        print_line "===================================================="
        print_line "$(printf "$FORMAT_COL" "Total number of files" "$count_total")"
        print_line "$(printf "$FORMAT_COL" "Total number of IMAGES" "$count_images")"
        print_line "$(printf "$FORMAT_COL" "Images failed" "$count_image_failed")"
        print_line "$(printf "$FORMAT_COL" "Images passed" "$count_image_passed")"
        print_line ""
    fi

    if [ $count_image_failed -eq 0 ]
    then
        exit_with_status_code 0
    else
        exit_with_status_code 1
    fi
fi

