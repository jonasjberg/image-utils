#!/usr/bin/env python
# -*- coding: utf-8 -*-

# CAUTION! *VERY* hacky code ahead!
#
# Temporary helper for renaming videos prior to rotating.
# Uses mplayer to preview the videos. VLC does auto-rotation from metadata,
# while mplayer seems to play the file as-is.
#
# After mplayer has finished, the user selects from a menu.
# The file is renamed to reflect the user selection.
#
# A proper solution to this would be to do both the preview, selection and
# actual processing at once. But this is at least better than an all manual
# approach for now.

import sys
import os
import argparse
import subprocess

parser = argparse.ArgumentParser(
    prog='interactive-video-rotation-renamer.py',
    description='Helper for renaming videos prior to rotating user other tools.'
                'The videos are played with mplayer, the user is then prompted '
                'for the desired rotation, whereby the file is renamed to '
                'reflect the selection.',
    epilog='Written by Jonas Sjöberg in 2016.'
)

parser.add_argument(dest='filenames',
                    metavar='filename',
                    nargs='*',
                    help='Videos to preview and rename. Files must match *.mp4.'
                         ' Everything else is ignored. See the source code for'
                         'more information ..')
args = parser.parse_args()

if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

mp4_files = [name for name in args.filenames if
             os.path.isfile(name) and name.endswith('.mp4')
             and not name.startswith('todo_')]

def prompt_for_rotation():
    prompt_options = {'1': 'Do not rotate',
                      '2': '90 degrees Clockwise',
                      '3': '90 degrees Counter-Clockwise',
                      '4': '90 degrees Clockwise with vertical flip',
                      '5': '180 degrees',
                      '7': 'Skip',
                      '8': 'Replay the video',
                      '9': 'Quit'}
    while True:
        for number, option in sorted(prompt_options.items()):
            print('[{}]  {}'.format(number, option))

        choice = raw_input('Please input selection: ')
        # print('User chose "{}"'.format(choice))

        if choice in prompt_options:
            return choice
        else:
            print('Invalid selection.')


def prepend_to_filename(prepend_str, filename):
    new_name = prepend_str + filename
    if os.path.exists(new_name):
        print('File exists: "{}" .. Skipping.'.format(new_name))
        return

    print('Renaming "{}" to "{}" ..'.format(filename, new_name))
    os.rename(filename, new_name)


for video in mp4_files:
    play_video = True
    while play_video:
        print('Playing video with mplayer: "{}"'.format(video))
        try:
            cmd = ['mplayer', '-really-quiet', video]
            cmd_output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            stdout = e.output
            retval = e.returncode

        choice = prompt_for_rotation()

        if choice != '8':
            play_video = False
        if choice == '9':
            exit(0)
        elif choice == '7':
            print('Skipping "{}" ..'.format(video))
            continue

        if choice == '1':
            prepend_to_filename('todo_0deg_', video)
        elif choice == '2':
            prepend_to_filename('todo_90deg_', video)
        elif choice == '3':
            prepend_to_filename('todo_90degCCW_', video)
        elif choice == '4':
            prepend_to_filename('todo_90degVert', video)
        elif choice == '5':
            prepend_to_filename('todo_180deg', video)
