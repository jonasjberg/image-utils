`image-utils`
================================================================================

*Copyright(c) 2016-2018 Jonas Sjöberg*  
<http://www.jonasjberg.com>  
<https://github.com/jonasjberg>  

Utilities related to editing and organizing photos/images.

Currently a work in progress with little to no documentation.  Do not expect
any help with support and/or troubleshooting any of these programs.  These are
personal, ad-hoc projects and GitHub offers free hosting, so here they are..

> This program is free software: you can redistribute it and/or modify it
> under the terms of the GNU General Public License as published by the
> Free Software Foundation, either version 3 of the License, or (at your
> option) any later version.
>
> This program is distributed in the hope that it will be useful, but WITHOUT
> ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
> FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
> more details.
>
> You should have received a copy of the GNU General Public License
> along with this program.  If not, see <http://www.gnu.org/licenses/>.

--------------------------------------------------------------------------------

`convert-keep-metadata.py`
--------------------------
Converts images from one format to another while keeping any metadata.

```
Usage:  convert-keep-metadata.sh [TARGET_EXTENSION] [FILES..]

Converts images from one format to another while keeping any metadata.
Given [FILES] are converted the format specified by [TARGET_EXTENSION]

After converting the image, metadata from the original is applied to
the target image. The destination image metadata may contain
duplicates, but metadata is not likely lost in the conversion.
Tranferring the original metadata in an exact form is probably a
non-trivial task..

    [TARGET_EXTENSION]
        See "convert -list format" for valid extensions.

    [FILES..]
        Path(s) to the images to convert.


convert-keep-metadata.sh is free. You can redistribute it and/or
modify it under the terms of the Do What The Fuck You Want To Public
License, Version 2. See http://www.wtfpl.net/ for more details.
convert-keep-metadata.sh is distributed WITHOUT ANY WARRANTY.
```


--------------------------------------------------------------------------------

`detect-bad-images.sh`
----------------------
Finds corrupt images by using external tools `exiftool` and `jpeginfo`.

Detects corrupt images from reading contents and metadata.
Good for sifting through data produced by data recovery or forensics.
Does rudimentary argument checking, but there are bound to be bugs.  Reads file
type from the "magic" header bytes, so file extension should not matter.

### Example usage:

* **Looping over results**  

    Generic usage template. Note that you should probably research handling
    "weird" file names properly, like those containing spaces, etc.

    ```bash
    ~/Bin/detect-bad-images.sh -b ~/Pictures/* | while IFS='\n' read -r f
    do
        [ -f "$f" ] || continue
        printf "do whatever with %s ..\n" "$f"
    done
    ```

* **Remove bad images**  

    Deletes images deemed "bad". There is no undoing deletion so be careful!

    ```bash
    find ~/Pictures -type f -exec ~/Bin/detect-bad-images.sh -d '{}' \;
    ```

### Complete usage information
To display usage information, run:
```bash
~/Bin/detect-bad-images.sh -h
```
Probably won't be complete though.


--------------------------------------------------------------------------------

`auto-adjust-photos.sh`
-----------------------
Auto-adjusts images based on metadata, file size and image dimensions.

Originally written for automatically modifying images uploaded to the 'Camera
Uploads' Dropbox folder. For instance, all images shot by a certain
camera/device might need to be resized or have the white balance auto-adjusted
**if** the image size is above a set threshold.

### Complete usage information
To display usage information, run:
```bash
~/Bin/auto-adjust-photos.sh -h
```
Probably not complete.


--------------------------------------------------------------------------------

`interactive-video-rotation-renamer.py`
---------------------------------------
Preview videos and interactively rename them to indicate what should be done by
other tools.


--------------------------------------------------------------------------------

`chrome-screencapture-renamer.sh`
---------------------------------
Renames images created by the "Full Page Screen Capture" Chrome plugin.


### Example usage:

1. Original files:

    ```bash
    [jonas:~/today] $ ls -1
    screencapture-carlosbecker-posts-jekyll-with-sass-1479831540449.png
    screencapture-jekyll-tips-jekyll-casts-control-flow-statements-in-liquid-1479831549597.png
    ```

2. Running the script:

    ```bash
    [jonas:~/today] $ ~/dev/projects/image-utils/chrome-screencapture-renamer.sh ~/today
    ```

3. Resulting file names:

    ```bash
    [jonas:~/today] $ ls -1
    2016-11-22T171900 carlosbecker-posts-jekyll-with-sass -- screenshot.png
    2016-11-22T171909 jekyll-tips-jekyll-casts-control-flow-statements-in-liquid -- screenshot.png
    ```


--------------------------------------------------------------------------------

`extract_base64_media.py`
-------------------------
Extracts base64-encoded media (currently only MIME-type 'image/jpeg') from
HTML-files.

For up-to-date usage information, run:
```bash
extract_base64_media.py --help
```


--------------------------------------------------------------------------------

`extract_exif_thumbnails.sh`
-------------------------
Extracts EXIF thumbnails from one or more files with MIME-type `image/jpeg`.
Extracted thumbnails are written to filenames on the form
`${ORIGINAL_FILENAME_WITHOUT_EXTENSION}_exif_thumbnail.jpg`.


--------------------------------------------------------------------------------

`microsoft_vision.py`
---------------------
Queries the Microsoft Vision API with images for information about visual
content found in the image. Requires a Microsoft Visual API key, which are
available for free (with some restrictions) at:
<https://www.microsoft.com/cognitive-services/en-us/sign-up>

For up-to-date usage information, run:
```bash
microsoft_vision.py --help
```

