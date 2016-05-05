image-utils
================================================================================

    Created : 2016-04-03
    Updated : 2016-04-07
    Author  : Jonas Sjöberg
    E-mail  : jomeganas@gmail.com
    GitHub  : https://github.com/jonasjberg 

Utilities related to editing and organizing photos/images.
Currently a work in progress, you are on your own.


--------------------------------------------------------------------------------

`detect-bad-images`
-------------------
Finds corrupt images by using external tools `exiftool` and `jpeginfo`.
    
Detects corrupt images from reading contents and metadata.
Good for sifting through data produced by data recovery or forensics.
Does rudimentary argument checking, but there are bound to be bugs.  Reads file
type from the "magic" header bytes, so file extension should not matter. 

### Complete usage information
To display usage information, run:

```bash
~/Bin/detect-bad-images -h
```

### Example usage:

* **Looping over results**  

    Generic usage template. Note that you should probably research handling
    "weird" file names properly, like those containing spaces, etc.

    ```bash
    ~/Bin/detect-bad-images -b ~/Pictures/* | while read f
    do 
        printf "do whatever with %s ..\n" "$f"
    done
    ```

* **Remove bad images**  
    
    Deletes images deemed "bad". There is no undoing deletion so be careful!

    ```bash
    find ~/Pictures -type f -exec ~/Bin/detect-bad-images -d '{}' \;
    ```


--------------------------------------------------------------------------------

`auto-adjust-photos`
--------------------
Auto-adjusts images based on metadata, file size and image dimensions.

Originally written for automatically modifying images uploaded to the 'Camera
Uploads' Dropbox folder. For instance, all images shot by a certain
camera/device might need to be resized or have the white balance auto-adjusted
**if** the image size is above a set threshold.

### Complete usage information
To display usage information, run:

```bash
~/Bin/auto-adjust-photos -h
```
