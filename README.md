image-utils
================================================================================

    Author  : Jonas Sjöberg
    Mail    : jomeganas@gmail.com
    Updated : 2016-04-03

Utilities related to editing and organizing photos/images.


`detect-bad-images`
-------------------
Finds corrupt images by using external tools 'exiftool' and 'jpeginfo'.
    
Detects corrupt images from reading contents and metadata.
Good for sifting through data produced by data recovery or forensics.
Reads file type from magic header bytes, file extension should not matter.

Works good enough if used with the '-b' option.

Example usage:
            
```bash
~/Bin/detect-bad-images -b ~/Pictures/* | while read f
do 
    echo "$f"
done
```

