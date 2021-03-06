#!/usr/bin/env bash
#
# detect-bad-images
# ~~~~~~~~~~~~~~~~~
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

SCRIPT_NAME="$(basename $0)"
DEBUG_MODE="false"

C_NORMAL=$(tput sgr0)
C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_BLUE=$(tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_CYAN=$(tput setaf 6)
HALFTAB='  '
FULLTAB='    '

# FUNCTION MSG_TYPE() -- Prints timestamped debug messages
# Messages can be of three different types (severity): ERROR, INFO and WARNING.
# Usage: msg_type info example informative text
#        msg_type warn some unexpected thing happened
#        msg_type "just text, no type specified"
function msg_type()
{
    if [ $# -gt 1 ]
    then
        local type="$1"
        shift
    fi

    local text="${@}"
    local label=''

    if [ "$type" == "debug" ] && [ "$DEBUG_MODE" != "true" ]
    then
        return
    elif [ "$brief" -eq 1 ]
    then
        return
    fi

    case $type in
        error ) label='ERROR'
                color=$C_RED    ;;
        info  ) label='+'
                color=$C_GREEN  ;;
        warn  ) label='!'
                color=$C_YELLOW ;;
        debug ) label='debug'
                color=$C_NORMAL ;;
        *     ) color=$C_NORMAL ;;
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
function exit_status()
{
    status=${1:-1}
    msg_type debug "Exiting with status [${status}]"
    exit ${status}
}

# Displays the usage information.
function print_help()
{
    msg_type info "\"${SCRIPT_NAME}\" -- Jonas Sjoberg 2016"
    msg_type info "Detects corrupt images from reading contents and metadata."
    msg_type info "Good for sifting through data produced by data recovery or forensics."
    msg_type info "Reads file type from magic header bytes, file extension should not matter."
    msg_type usage ""
    msg_type usage "usage: ${SCRIPT_NAME} [options] [file(s)]"
    msg_type usage "options:    -b   print corrupt files only (less verbose)"
    msg_type usage "            -d   delete files that fail the tests (USE WITH CAUTION)"
    msg_type usage "            -h   display help and usage information"
    msg_type usage "            -s   print test summary/statistics"
}

# Main routine that actually does the analysis.
function main()
{
    arg="${1:-}"

    [ -z "$arg" ] && { msg_type warn "Got null argument .."            ; return 2 ; }
    [ -e "$arg" ] || { msg_type warn "File \"${arg}\" does not exist." ; return 2 ; }
    [ -f "$arg" ] || { msg_type warn "\"${arg}\" is not a file."       ; return 2 ; }

    # Check file type by reading magic header bytes.
    #arg_mime=$(file --brief --mime -- "$arg" | grep image)
    unset arg_mime
    case $(file --mime-type --brief -- "$arg") in
        image/j*g)  arg_mime=jpg ;;
        image/png)  arg_mime=png ;;
        *)                       ;;
    esac

    if [ -z "$arg_mime" ]
    then
        msg_type warn "File \"${arg}\" is not an image."
        return 2
    fi

    # Extra newline for readability ONLY if brief mode is disabled.
    [ "$brief" -eq 0 ] && printf "\n"
    msg_type info "Checking integrity of image file \"${arg}\" .."

    if [ "$brief" -eq 1 ]
    then
        check_image_with_exiftool "$arg" >/dev/null
    else
        check_image_with_exiftool "$arg"
    fi
    exiftool_result=$?

    jpeginfo_result=0
    if [ "$arg_mime" == "jpg" ]
    then
        if [ "$brief" -eq 1 ]
        then
            check_image_with_jpeginfo "$arg" >/dev/null
        else
            check_image_with_jpeginfo "$arg"
        fi
        jpeginfo_result=$?
    fi

    if [ $exiftool_result -eq 0 ] && [ $jpeginfo_result -eq 0 ]
    then
        return 0
    else
        msg_type error "Image \"${arg}\" failed the tests!"
        [ "$brief" -eq 1 ] && printf "%s\n" "${arg}"
        return 1
    fi
}

function check_image_with_exiftool()
{
    exiftool -warning -quiet -ignoreMinorErrors "$1" | tr -s ' '
}

function check_image_with_jpeginfo()
{
    jpeginfo --check --quiet --lsstyle "$1"
}

function print_result_line()
{
    printf "%-60.60s\n" "$*"
}

function check_dependencies_are_available()
{
    required_programs="exiftool jpeginfo"

    for program in $required_programs
    do
        if ! command -v "$program" >/dev/null 2>&1
        then
            msg_type error "Missing required executable \"${program}\" .. Aborting."
            exit_status 127
        fi
    done
}


# ______________________________________________________________________________
# PROGRAM INVOCATION CODE EXECUTION STARTS HERE
TIMESTAMP="$(date +%F\ %H:%M:%S)"
msg_type debug "${SCRIPT_NAME} started at ${TIMESTAMP}"

# Set default options.
stats=0
brief=0
delete=0


if [ $# -eq 0 ]
then
    # No arguments provided.
    msg_type warn "No arguments provided."
    msg_type warn "For help run: \"${SCRIPT_NAME} -h\""
    exit_status 1
else
    # Make sure required programs are available.
    check_dependencies_are_available

    # Parse arguments.
    while getopts bdhs var
    do
        case "$var" in
            b) brief=1       ;;
            d) delete=1      ;;
            h) print_help    ;
               exit_status 0 ;;
            s) stats=1       ;;
        esac
    done

    shift $(( $OPTIND - 1 ))

    count_total=0
    count_images=0
    count_image_passed=0
    count_image_failed=0
    # Run main routine on arguments.
    for arg in "$@"
    do
        count_total=$(( $count_total + 1))

        main "$arg"

        status="$?"
        # Exit status:   0  image OK!
        #                1  image failed test
        #                2  skipped (not an image, etc)
        if [ $status -eq 2 ]
        then
            msg_type debug "Skipped \"${arg}\" .."
            continue
        fi

        if [ $status -eq 1 ]
        then
            count_images=$(( $count_images + 1 ))
            count_image_failed=$(( $count_image_failed + 1 ))

            # Remove image if delete option is enabled.
            if [ $delete -eq 1 ]
            then
                if [ $brief -eq 0 ]
                then
                    msg_type info "Deleting \"${arg}\" .."
                    rm -vf -- "${arg}"
                else
                    rm -f -- "${arg}"
                fi
            fi
        elif [ $status -eq 0 ]
        then
            count_images=$(( $count_images + 1 ))
            count_image_passed=$(( $count_image_passed + 1 ))
        fi
    done

    # Print results with a summary of all tests, IF:
    # brief mode is disabled AND stats mode is enabled.
    # Keep text width below 60 columns to avoid messy output in small terminal windows.
    if [ $brief -ne 1 ] && [ $stats -gt 0 ]
    then
        TAB='    '
        SEP=':'
        FORMAT_COL="%-22.22s ${SEP} %-35.35s\n"
        print_result_line ""
        print_result_line "----------------------------------------------------"
        print_result_line "TEST RUN RESULTS SUMMARY:"
        print_result_line "$(printf "$FORMAT_COL" "Total number of files" "$count_total")"
        print_result_line "$(printf "$FORMAT_COL" "Total number of IMAGES" "$count_images")"
        print_result_line "$(printf "${C_GREEN}%22.22s${C_NORMAL} ${SEP} %-35.35s\n" "[PASSED]" "$count_image_passed")"
        print_result_line "$(printf "${C_RED}%22.22s${C_NORMAL} ${SEP} %-35.35s\n" "[FAILED]" "$count_image_failed")"
    fi

    if [ $count_image_failed -eq 0 ]
    then
        exit_status 0
    else
        exit_status 1
    fi
fi
