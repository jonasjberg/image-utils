#!/usr/bin/python
# 
# http://android.stackexchange.com/questions/58087/read-content-of-thumbdata-file
# http://android.stackexchange.com/a/109739
#

import os
import sys

JPEG_HEADER_START = '\xff\xd8'
JPEG_HEADER_END = '\xff\xd9'


def extract_files_from_thumbdata_file(path):
    """extract files from Android thumbdata3 file"""

    with open(path, 'rb') as f:
        thumb_data = f.read()

    count = 0
    start = 0
    while True:
        x1 = thumb_data.find(JPEG_HEADER_START, start)
        if x1 < 0:
            break
        x2 = thumb_data.find(JPEG_HEADER_END, x1)
        jpg = thumb_data[x1:x2 + 1]

        out_file = 'extracted{:03d}.jpg'.format(count)
        with open(out_file, 'wb') as fw:
            fw.write(jpg)

        start = x2 + 2
        count += 1

    print('Wrote {} files'.format(count))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: {} [FILE [FILE ...]]'.format(sys.argv[0]))
        print('')
        print(' NOTE: Any files named "extracted%03d.jpg" in working ')
        print('       directory could be overwritten! Use with caution.')
        sys.exit(1)
    else:
        for arg in sys.argv[1:]:
            if os.path.isfile(arg):
                if not os.access(arg, os.R_OK):
                    print('Not authorized to read file: "{}"'.format(str(arg)))
                    continue
                else:
                    extract_files_from_thumbdata_file(arg)
            else:
                print('Not a file: "{}"'.format(str(arg)))
                continue

        sys.exit(0)
