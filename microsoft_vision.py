#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#   Written in 2017 by Jonas Sjöberg
#   http://www.jonasjberg.com
#   https://github.com/jonasjberg
#   _____________________________________________________________________
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#   _____________________________________________________________________


# This is me playing around with the Microsoft Vision API on a friday night.

from __future__ import print_function

import sys
import os
import json
import urllib
import argparse
import logging
import requests

# Python 2.6+
if sys.version_info[0] == 2:
    from urllib import urlencode
    import httplib

# Python 3.x
if sys.version_info[0] == 3:
    from urllib.parse import urlencode
    import http.client as httplib

PROGRAM_NAME = os.path.basename(__file__)
IMAGE_EXTENSIONS = ['.png', '.jpg', '.jpeg']


def arg_is_readable_file_or_dir(arg):
    """
    Used by argparse to validate argument is a readable file.
    Handles expansion of '~' into the proper user "$HOME" directory.
    Throws an exception if the checks fail. Exception is caught by argparse.

    Args:
        arg: The argument to validate.

    Returns: The expanded absolute path specified by "arg" if valid.

    """
    if os.path.exists(arg):
        if arg.startswith('~/'):
            arg = os.path.expanduser(arg)

        if (os.path.isfile(arg) or os.path.isdir(arg)) \
                and os.access(arg, os.R_OK):
            return os.path.normpath(os.path.abspath(arg))

    raise argparse.ArgumentTypeError('Invalid file/path: "{}"'.format(str(arg)))


def get_images(path_list):
    """
    Takes a list of files and directories and returns files with extension
    matching any in "IMAGE_EXTENSIONS".
    The directories are only traversed one level, I.E. not recursively.

    :param path_list: List of paths to files and/or directories.
    :return: Files whose extensions match those in "IMAGE_EXTENSIONS".
    """
    out = []

    for path in path_list:
        if os.path.isdir(path):
            _files = [f for f in os.listdir(path) if
                      os.path.isfile(os.path.join(path, f))]
            _images = [f for f in _files for ext in IMAGE_EXTENSIONS if
                       f.lower().endswith(ext.lower())]
            out += _images
        elif os.path.isfile(path):
            for ext in IMAGE_EXTENSIONS:
                if path.lower().endswith(ext.lower()):
                    out += [path]

    return out


def query_api(image_file, api_key):
    """
    Queries the Microsoft Vision API with a given image.

    :param image_file: Path to the image file used in the query.
    :return: The API JSON data response.
    """
    if not api_key:
        log.error('Unable to continue without an API key!')
        return False

    headers = {
        'Content-Type': 'application/octet-stream',
        'Ocp-Apim-Subscription-Key': api_key,
    }

    params = urlencode({
        'maxCandidates': '1',
    })

    content = open(image_file, 'rb')
    try:
        conn = httplib.HTTPSConnection('westus.api.cognitive.microsoft.com')
        conn.request("POST", "/vision/v1.0/describe?%s" % params, content,
                     headers)
        response = conn.getresponse()
        response_data = response.read().decode('utf-8')
        json_data = json.loads(response_data)
        conn.close()
        return json_data

    except Exception as e:
        log.error('[ERROR] Caught exception when querying the API;')
        if e:
            log.error(str(e))
        return False


def get_caption_text(json_data):
    """
    Extracts the caption text from the JSON response.

    :param json_data: API JSON response.
    :return: The image caption text.
    """
    try:
        caption = json_data['description']['captions'][0]['text']
    except KeyError as e:
        log.error('[ERROR] Unable to get caption text: ', str(e))
    else:
        return caption


def main(paths, api_key, dump_response=False, print_caption=True):
    """
    Main program entry point, iterates over paths to images and queries
    the api with the specified API key.

    :param paths: List of paths to images.
    :param api_key: Microsoft Vision API key.
    :param dump_response: True if the JSON data response should be printed.
    :param print_caption: True if the image caption should be printed.
    """
    images = get_images(paths)
    log.debug('Got images:')
    for number, image in enumerate(images):
        log.debug('[{:03d}] "{}"'.format(number, str(image)))

    try:
        log.debug('Start of processing; querying the Microsoft API ..')

        for image in images:
            log.info('Querying API with image: "{}"'.format(str(image)))

            response = query_api(image, api_key)

            if not response:
                log.error('Unable to query to API')
                sys.exit(1)

            log.info('Received query response')

            _image_basename = os.path.basename(image)
            if dump_response:
                print('Response JSON data for image '
                      '"{}":'.format(str(_image_basename)))
                print(json.dumps(response, indent=8))
            if print_caption:
                caption = get_caption_text(response)
                if caption:
                    print('"{}": {}'.format(str(_image_basename),
                                            str(caption)))

    except KeyboardInterrupt:
        sys.exit('Received Keyboard Interrupt; Exiting ..')


if __name__ == '__main__':
    _valid_extensions = ', '.join('*' + ext for ext in IMAGE_EXTENSIONS)

    parser = argparse.ArgumentParser(
        description='Simple demo program written for demonstrating use of the '
                    'Microsoft Vision API. \n Written by Jonas Sjöberg in 2017.'
                    ' License is the GNU General Public License.'
    )
    parser.add_argument(
        help='Images and/or paths to directories containing images. '
             'Ignores all files except those whose extension matches: "{}". '
             'Directory traversal is non-recursive.'.format(_valid_extensions),
        dest='input_files_or_dir',
        type=arg_is_readable_file_or_dir,
        nargs='*',
        metavar='IMAGE_PATH'
    )
    parser.add_argument(
        '-d', '--dump',
        help='Prints all API query responses in JSON format.',
        dest='dump',
        action='store_true',
        default=False
    )
    parser.add_argument(
        '-c', '--caption',
        help='Prints the image caption.',
        dest='dump_caption',
        action='store_true',
        default=True
    )
    parser.add_argument(
        '-v', '--verbose',
        help='Increase output verbosity.',
        dest='verbose',
        action='store_true',
        default=False,
    )
    parser.add_argument(
        '-k', '--api-key',
        help='API key. Required to use the Microsoft Vision API',
        dest='api_key',
        required=True,
    )

    args = parser.parse_args()

    if args.verbose:
        log_format = '{} %(asctime)s %(levelname)-8.8s %(funcName)-25.25s' \
                     '(%(lineno)3d) %(message)s'.format(PROGRAM_NAME)
        logging.basicConfig(level=logging.DEBUG, format=log_format,
                            datefmt='%Y-%m-%d %H:%M:%S')
    else:
        log_format = '{} %(asctime)s %(levelname)-8.8s' \
                     ' %(message)s'.format(PROGRAM_NAME)
        logging.basicConfig(level=logging.WARN, format=log_format,
                            datefmt='%Y-%m-%d %H:%M:%S')

    log = logging.getLogger()

    if not args.input_files_or_dir:
        log.info('No images specified. Use "--help" for usage information')
        sys.exit(0)

    main(args.input_files_or_dir, args.api_key, args.dump, args.dump_caption)
