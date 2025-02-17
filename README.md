 # zzzFORTH

Also called ZFOS, an operating system, written in 32-bit Intel-assembly and FORTH.

The best FORTH tutorial is "Starting FORTH by Leo Brodie":
https://www.forth.com/starting-forth/

## Features

- Resolutions: 1024x768x16 or 640x480x16 (for Eee PC) 
- Multitasking (but only one core or CPU is used)
- Can boot from Floppy/HD/USB-MSD
- IDE hard disk driver                        (in FORTH, in ZFOS/fthsrc/; also the ones below)
- USB(EHCI, XHCI) driver 
- HDAUDIO driver (very limited)
- BLOCK
- HEXVW, HEXED
- TXTVW, TXTED
- SIN, COS, TAN, SQRT (fixed point math)
- LINE, POLYGON(can be filled), CIRCLE(can be filled), PAINT
- Sutherland-Cohen line-clipping 
- Sutherland-Hodgman polygon clipping
- BEZIERQ, BEZIERC
- QOI image format (decode/code) supported
- 3D (fixed point math) (e.g. rotating cubes)
- Astronomical algorithms (fixed point decimal)

See ZFOS/docs for details

The original assembly code of the drivers (IDE, HDAUDIO and USB(XHCI, EHCI)) are available in the ASM folder.

## How to build and start

Add executable permission to scripts (in zzzFORTH or ZFOS folder):

chmod +x [star].sh

./buildAll.sh

See docs/emulators.txt or docs/USBBoot.txt on how to start.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

