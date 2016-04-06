#!/usr/bin/env python



import exiftool

files = ["a.jpg", "b.png", "c.tif"]
with exiftool.ExifTool() as et:
    metadata = et.get_metadata_batch(files)
for d in metadata:
    print("{:20.20} {:20.20}".format(d["SourceFile"],
                                     d["EXIF:DateTimeOriginal"]))
