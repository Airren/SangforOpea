#!/usr/bin/env bash

sudo dmesg | grep -i 915

hwinfo --display

lspci | grep -i vga
lspci | grep -i vga | xargs -n 1 lspci -vvv -s