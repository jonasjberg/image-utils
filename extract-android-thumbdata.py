#!/usr/bin/python
# 
# http://android.stackexchange.com/questions/58087/read-content-of-thumbdata-file
# http://android.stackexchange.com/a/109739
#

JPEG_FILE_START = '\xff\xd8'
JPEG_FILE_END = '\xff\xd9'


def extract_files_from_thumbdata_file(path):
    """extract files from Android thumbdata3 file"""

    f = open(path, 'rb')
    tdata = f.read()
    f.close()

    count = 0
    start = 0
    while True:
        x1 = tdata.find(JPEG_FILE_START, start)
        if x1 < 0:
            break
        x2 = tdata.find(JPEG_FILE_END, x1)
        jpg = tdata[x1:x2 + 1]
        count += 1
        fname = 'extracted%d03.jpg' % (count)
        fw = open(fname, 'wb')
        fw.write(jpg)
        fw.close()
        start = x2 + 2


if __name__ == '__main__':
    extract_files_from_thumbdata_file('thumbdata3.dat')
