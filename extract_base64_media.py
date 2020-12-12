#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# extract_base64_media.py
# =======================
# Written in 2017 by Jonas Sjöberg
# http://www.jonasjberg.com
# https://github.com/jonasjberg
# _____________________________________________________________________
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
# _____________________________________________________________________


import base64
import logging
import os
import re

PROGRAM_NAME = os.path.basename(__file__)


RE_ENCODED_JPEG = re.compile(
    r'^.*?src="data:image/jpeg;charset=utf-8;base64,(.*)%0A">\s*',
    re.DOTALL | re.MULTILINE,
)
RE_ENCODED_PNG = re.compile(
    r'data:image/png(?:;charset=utf-8)?;base64,(.*)',
    re.DOTALL | re.MULTILINE,
)


def validate_file(arg):
    if os.path.exists(arg) and os.path.isfile(arg) and os.access(arg, os.R_OK):
        if arg.startswith('~/'):
            arg = os.path.expanduser(arg)
        return os.path.normpath(os.path.abspath(arg))

    raise argparse.ArgumentTypeError('Invalid file: "{}"'.format(str(arg)))


def decode_and_write_to_disk(found_data, dry_run=False):
    def _format_filename(_number, _extension):
        return 'extracted_{:04d}.{!s}'.format(_number, _extension)

    i = 0
    write_count = 0
    error_count = 0
    for image in found_data:
        raw_data = image['data']
        raw_data = raw_data.strip()
        if not raw_data:
            log.warning('Skipping (empty raw_data) ..')
            continue

        outfile = _format_filename(i, image['filetype'])
        while os.path.exists(outfile):
            log.debug('Destination exists: "{}"'.format(outfile))
            i += 1
            outfile = _format_filename(i, image['filetype'])

        # TODO: Handle data encoding properly.
        raw_data = raw_data.replace('%0A', '')
        raw_data = raw_data.encode('utf-8')

        if dry_run:
            log.info('[--dry-run] Would have written {} bytes to file '
                     '"{}" ..'.format(len(raw_data), str(outfile)))
        else:
            if os.path.exists(outfile):
                log.error('Destination exists: "{}"'.format(outfile))
                error_count += 1
                continue

            log.info('Writing {} bytes to "{}" ..'.format(len(raw_data),
                                                          str(outfile)))
            try:
                with open(outfile, "wb") as fh:
                    fh.write(base64.decodebytes(raw_data))
                    # outfile_raw = 'extracted_{0:04d}.raw'.format(i)
                    # with open(outfile_raw, "wb") as fhr:
                    #    fhr.write(raw_data)
            except Exception:
                log.error('Write (decode) operation failed ..')
                error_count += 1
            else:
                write_count += 1

        i += 1

    log.info('[DONE] All Finished!')
    if write_count > 0:
        log.info('Successfully wrote {} files to disk.'.format(write_count))
    if error_count > 0:
        log.info('Failed to decode/write {} files.'.format(error_count))


def extract_encoded_images_from_html(filename):
    results = []

    with open(filename) as file_data:
        for num, line in enumerate(file_data, 1):
            match_jpg = RE_ENCODED_JPEG.match(line)
            if match_jpg:
                log.debug('Found base64 encoded jpeg image on line %d', num)
                results.append({
                    'filetype': 'jpg',
                    'data': match_jpg.group(1),
                })

            log.debug('Trying to matching line: %s', line)
            match_png = RE_ENCODED_PNG.match(line)
            if match_png:
                log.debug('Found base64 encoded PNG image on line %d', num)
                results.append({
                    'filetype': 'png',
                    'data': match_png.group(1),
                })

    log.debug('Extracted %d images ..', len(results))
    return results


if __name__ == '__main__':
    import argparse

    argparser = argparse.ArgumentParser(PROGRAM_NAME,
        description='Extracts base64-encoded images from HTML files. Files '
                    'are written to the current directory with basename '
                    'extracted_0000.jpg". Numbers are incremented to prevent '
                    'clobbering existing files.')
    argparser.add_argument('-v', '--verbose',
                           action='store_true', default=False, dest='verbose',
                           help='Increase output verbosity.')
    argparser.add_argument('-d', '--dry-run',
                           action='store_true', default=False, dest='dry_run',
                           help='Simulate what would happen but do not actually'
                                'modify/write anything.')
    argparser.add_argument(dest='files', nargs='*', metavar='FILE',
                           type=validate_file,
                           help='File to convert.')

    args = argparser.parse_args()

    if args.verbose:
        log_format = '%(asctime)s %(levelname)-8.8s %(funcName)-25.25s' \
                     '(%(lineno)3d) %(message)s'
        logging.basicConfig(level=logging.DEBUG, format=log_format,
                            datefmt='%Y-%m-%d %H:%M:%S')
    else:
        log_format = '%(levelname)-8.8s %(message)s'
        logging.basicConfig(level=logging.INFO, format=log_format)

    log = logging.getLogger()

    encoded_data = []
    for f in args.files:
        log.info('Processing file: "{}" ..'.format(str(f)))
        encoded_data += extract_encoded_images_from_html(f)

    if encoded_data:
        log.info('[FINISHED] Found {} encoded files'.format(len(encoded_data)))
        decode_and_write_to_disk(encoded_data, args.dry_run)
    else:
        log.info('[FINISHED] No data was found')
