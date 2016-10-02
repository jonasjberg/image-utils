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
    prompt_options = {
        '1': {'description': 'Do not rotate (reencode only)',
              'action': 'todo_0deg_'},
        '2': {'description': '90 degrees Clockwise',
              'action': 'todo_90deg_'},
        '3': {'description': '90 degrees Counter-Clockwise',
              'action': 'todo_90degCCW_'},
        '4': {'description': '90 degrees Clockwise with vertical flip',
              'action': 'todo_90degVert_'},
        '5': {'description': '180 degrees',
              'action': 'todo_180deg_'},
        '7': {'description': 'Skip',
              'action': 'skip'},
        '8': {'description': 'Replay the video',
              'action': 'replay'},
        '9': {'description': 'Quit',
              'action': 'quit'}
    }

    while True:
        print('__________________________________________________\n')
        for number, option in sorted(prompt_options.items()):
            print('[{}]  {}'.format(number, option['description']))

        choice = raw_input('\nPlease input selection: ')

        if choice in prompt_options:
            return prompt_options[choice]['action']
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
        print('\n\nPlaying video with mplayer: "{}"'.format(video))
        try:
            cmd = ['mplayer', '-really-quiet', video]
            cmd_output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            stdout = e.output
            retval = e.returncode
            print('[ERROR] mplayer returned exit code {} and;'.format(retval))
            print(stdout)

        choice = prompt_for_rotation()

        if choice == 'quit':
            exit(0)
        if choice == 'replay':
            continue
        if choice == 'skip':
            print('Skipping "{}" ..'.format(video))
            play_video = False
            continue

        play_video = False
        prepend_to_filename(choice, video)
