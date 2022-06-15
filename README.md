# scr2AnimGIF
Speccy screen file (.scr) converter to animated GIF files.

This program will create animated GIF Files of your favourite .scr files as if they're loading on a real speccy. It's a command line program:

SCR2AnimGIF.exe Filename -o Outfilename -hw (48k/128k) -hiss -wobble -pa/pb/pp -header [name] -border (full/partial/small/none) -opt -cls n -attrs -fb n

Options explained:

-o Specify an output filename. If not specified, input filename is assumed and given a .gif extension.

-hw Specify hardware - 48k or 128k. Affects border stripe sizes and speed.

-hiss enable tape hiss - roughs up the border edges a little.

-wobble enables tape wobble - a wowing effect

-pa -b -pp Specifies a pause in seconds - pa = pause after load, pb = pause before load, pp = pause while seeking pilot (usually 1 second for ROM loader)

-header adds a header block. Optional (up to ten characters) name can be specified and will appear after "Bytes:" before screen loads

-border specifies border size. full = 352x296, partial = 320x240, small = 4 pixel wide border, none = just PAPER area, no border stripes.

-opt if present, optimises the display area for loading speed. 

-cls n Allows you to specify the starting screen colour. It's an ATTR byte, so 56 by default (black ink, white paper, no bright, no flash)

-attrs - only load the attributes from the .scr file. Manic Miner looks good with this.

-fb lets you specify the final border colour after loading is complete. Default 7 (white).

-sound creates a wav file of the loading sound

-mp4 outputs an mp4 video created from the gif and (if you have the -sound switch enabled) with full sound. This requires FFMpeg.exe to be present somewhere in your path - and it MUST be the correct bit version (x86 or x64) depending on which version of the Scr2AnimGIF executable you are running.

FLASH and BRIGHT attributes work as you would expect.
