#!/usr/bin/python
# 
# http://android.stackexchange.com/questions/58087/read-content-of-thumbdata-file
# http://android.stackexchange.com/a/109739
#
"""extract files from Android thumbdata3 file"""

f=open('thumbdata3.dat','rb')
tdata = f.read()
f.close()

ss = '\xff\xd8'
se = '\xff\xd9'

count = 0
start = 0
while True:
    x1 = tdata.find(ss,start)
    if x1 < 0:
        break
    x2 = tdata.find(se,x1)
    jpg = tdata[x1:x2+1]
    count += 1
    fname = 'extracted%d03.jpg' % (count)
    fw = open(fname,'wb')
    fw.write(jpg)
    fw.close()
    start = x2+2