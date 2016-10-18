#!/bin/bash

pushd initramfs
find . -print0 | cpio --null -ov --format=newc | gzip > ../initramfs.cpio.gz
popd
