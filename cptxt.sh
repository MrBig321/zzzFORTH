#!/bin/bash

sudo mount -o loop output/file.img /media/floppy
sleep 2
sudo rm /media/floppy/USB.TXT
sudo rm /media/floppy/USBFS.TXT
sudo cp output/USB.TXT /media/floppy
sudo cp output/USBFS.TXT /media/floppy
sleep 2
sudo umount /media/floppy

cp output/file.img ~

