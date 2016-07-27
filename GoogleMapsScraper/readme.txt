Code to download streetview images and oblique images:

--------------------------------------------------------------------
Download Streetview Images + Depth Maps:

0. Compile by running compile.sh (maybe need to install other packages, read compile.sh)

1. Open Google Maps in the browser. Locate the place you want to start download (either indoor or outdoor).

2. Drop the little person onto the map to go into the streetview mode, i.e. you will see a streetview images now (either indoor or outdoor).

3. Click the share link button to get the link. For example,
https://maps.google.com/maps?q=Met,+New+York,+NY&hl=en&ll=40.779588,-73.963291&spn=0.009473,0.018153&sll=40.772648,-73.9843&sspn=0.018948,0.036306&t=h&hq=Met,+New+York,+NY&z=16&layer=c&cbll=40.779588,-73.963291&panoid=dHaKL0lk5Xa0wpT9nSIX3g&cbp=12,354.68,,0,3.09

4. You can see "panoid=dHaKL0lk5Xa0wpT9nSIX3g" in this link, the panoid is the seed for downloading "dHaKL0lk5Xa0wpT9nSIX3g"

5. Put this in my code bfs_download.m as seed_panoid, change download_number to be a number you want to download. And run the code.

Only tested in Linux.

--------------------------------------------------------------------

Download Oblique Images + Depth Maps:

1. Set the location parameter in downloadOblique.m

2. Run downloadOblique.m