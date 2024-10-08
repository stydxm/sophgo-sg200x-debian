#!/bin/sh
docker run --privileged -it --rm -v ./configs/:/configs -v ./image:/output sg200x-debian-builder make BOARD=licheervnano image
