#!/bin/bash

KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.6.2.tar.xz
BUSYBOX_URL=https://www.busybox.net/downloads/binaries/busybox-x86_64
PYTHON_URL=https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tar.xz

D=`mktemp -d`
pushd $D

function on_exit {
    popd
    rm -rf $D
}
trap on_exit EXIT

set -e

echo Downloading and building kernel...
kern_filename=$(basename $KERNEL_URL)
kern_name=$(basename -s .tar.xz $kern_filename)
wget $KERNEL_URL && tar -xf $kern_filename


function build_python {
    PYTHON_VER=$(basename -s .tar.xz $PYTHON_URL)

    echo Downloading and building $PYTHON_VER...
    wget $PYTHON_URL
    tar -xf $PYTHON_VER*
    cd $PYTHON_VER

    sed '1s/^/*static*\n/' Modules/Setup.dist > Modules/Setup
    ./configure LDFLAGS="-static -static-libgcc" CPPFLAGS="-static"

    sed -i '/LINKFORSHARED=/c\LINKFORSHARED=' Makefile
    make
}
