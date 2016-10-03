#!/usr/bin/env python3
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
import shutil
import logging

# Video player executable to use for previewing the videos.
VIDEO_PLAYER = 'mplayer'
VIDEO_PLAYER_ARGS = ['-really-quiet']

parser = argparse.ArgumentParser(
    prog='interactive-video-rotation-renamer.py',
    description='Helper for renaming videos prior to rotating using other '
                'tools. The videos are opened with {player}, the user is then '
                'prompted for the desired rotation, whereby the file is '
                'renamed to reflect the selection.'.format(player=VIDEO_PLAYER),
    epilog='Written by Jonas Sjöberg in 2016.'
)

parser.add_argument(dest='filenames',
                    metavar='filename',
                    nargs='*',
                    help='Videos to preview and rename. Files must match *.mp4.'
                         ' Everything else is ignored. See the source code for'
                         'more information ..')
parser.add_argument('-v', '--verbose',
                    dest='verbose',
                    action='store_true',
                    help='Enable verbose (debug) output.')
args = parser.parse_args()

LOG_FORMAT = '%(asctime)s  %(levelname)-8.8s  %(message)-120.120s'
if args.verbose:
    logging.basicConfig(level=logging.DEBUG, format=LOG_FORMAT)
else:
    logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def exit_program():
    logging.debug('Exiting')
    exit(0)


if len(sys.argv) == 1:
    parser.print_help()
    exit_program()

if not shutil.which(cmd=VIDEO_PLAYER):
    print('This program needs "{player}" to run. Please install "{player}" or '
          'specify an alternate video player in the script source variable '
          '"VIDEO_PLAYER".'.format(player=VIDEO_PLAYER))
    exit_program()


mp4_files = [name for name in args.filenames if
             os.path.isfile(name) and name.endswith('.mp4')
             and not name.startswith('todo_')]
logging.debug('Got {} files. File listing:'.format(len(mp4_files)))
for number, file in enumerate(mp4_files):
    logging.debug('[{}] "{}"'.format(number, file))


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

        choice = input('\nPlease input selection: ')

        if choice in prompt_options:
            return prompt_options[choice]['action']
        else:
            logging.warning('Invalid selection.')


def prepend_to_filename(prepend_str, filename):
    new_name = prepend_str + filename
    if os.path.exists(new_name):
        logging.warning('File exists: "{}" .. Skipping.'.format(new_name))
        return

    logging.info('Renaming "{}" to "{}" ..'.format(filename, new_name))
    os.rename(filename, new_name)


for video in mp4_files:
    play_video = True
    while play_video:
        logging.debug('Using {p} to preview video: "{v}"'.format(p=VIDEO_PLAYER,
                                                                 v=video))
        try:
            cmd = [VIDEO_PLAYER] + VIDEO_PLAYER_ARGS + [video]
            cmd_output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            stdout = e.output
            retval = e.returncode
            logging.error('[ERROR] {p} returned exit code {c} and the following'
                          ' standard output:'.format(p=VIDEO_PLAYER, c=retval))
            logging.error(line for line in stdout)

        choice = prompt_for_rotation()

        if choice == 'quit':
            exit_program()
        elif choice == 'replay':
            logging.debug('Replaying video ..')
            continue
        elif choice == 'skip':
            logging.debug('Skipping "{}" ..'.format(video))
            play_video = False
            continue
        else:
            play_video = False
            prepend_to_filename(choice, video)

exit_program()
