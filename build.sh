#!/bin/bash

# Set the versions you wish to build. The versions below have been tested and
# are verified as working. Make sure to update the SHA1 checksums if you alter
# the versions.
PYTHON_VER=3.5.1
PYTHON_SHA1=0186da436db76776196612b98bb9c2f76acfe90e
BUSYBOX_VER=1.24.2
BUSYBOX_SHA1=03e6cfc8ddb2f709f308719a9b9f4818bc0a28d0
KERNEL_VER=4.6.2
KERNEL_SHA1=4a80351043c69adebdb692046206cdc9fdbe4b5c

# Set the directory to store the downloaded archives in. This will not be cleared.
DOWNLOAD_DIR=./download

# Set the directory for the initramfs to be built to. This will not be
# deleted once build is complete, but will be cleared each time the build
# starts.
INITRAMFS_DIR=./initramfs


##########################################
# You shouldn't need to edit below here. #
##########################################

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PYTHON_URL=https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tar.xz
BUSYBOX_URL=http://busybox.net/downloads/busybox-$BUSYBOX_VER.tar.bz2
KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VER:0:1}.x/linux-$KERNEL_VER.tar.xz

# Expand out the full path to dist dir as this needs to be absolute.
DOWNLOAD_DIR=$(realpath $DOWNLOAD_DIR)
INITRAMFS_DIR=$(realpath $INITRAMFS_DIR)

# make(1) options
MAKEOPTS=-j$(($(grep 'processor' /proc/cpuinfo | wc -l)-1))

# Create temporary directory and add cleanup handler.
d=`mktemp -d`
pushd $d >/dev/null
function cleanup {
    popd >/dev/null
    rm -rf $d
}
trap cleanup EXIT

# Clean up from the last build.
rm -rf $INITRAMFS_DIR
mkdir -p $INITRAMFS_DIR
rm -f $SOURCE_DIR/initramfs.gz

# verify_sha1(sha1, file)
#  sha1: the expected hash
#  file: filename to check
function verify_hash {
    echo "$1 $2" | sha1sum -c - >/dev/null 2>&1
}

# download_and_verify(url, sha1)
#  url: the URL to download
#  sha1: the expected sha1 hash of the file
function download_and_verify {
    url="$1"
    sha1="$2"
    filename=`basename $url`
    path="$DOWNLOAD_DIR/$filename"
    if [ -f $path ] ; then
        verify_hash $sha1 $path && echo "Successfully verified $filename" && return 0
    fi
    wget -q $url -O $path
    verify_hash $sha1 $path
    if [ $? -eq 0 ] ; then
        echo "Successfully downloaded and verified $filename"
        return 0
    else
        echo "Error: failed to download or verify $filename, aborting"
        exit 3
    fi
}

function preseed_initramfs {
    pushd $INITRAMFS_DIR >/dev/null
    mkdir proc sys dev bin lib
    cp $SOURCE_DIR/init .
    chmod +x init
    popd >/dev/null
    echo "Created new initramfs structure at $INITRAMFS_DIR"
}

function build_python {
    echo "Downloading and extracting Python $PYTHON_VER..."
    download_and_verify $PYTHON_URL $PYTHON_SHA1
    tar -xf "$DOWNLOAD_DIR/$(basename $PYTHON_URL)"

    pushd Python-* >/dev/null
    echo "Building Python $PYTHON_VER..."
    sed '1s/^/*static*\n/' Modules/Setup.dist > Modules/Setup
    ./configure LDFLAGS="-static -static-libgcc" CPPFLAGS="-static" >>python.log 2>&1
    sed -i '/LINKFORSHARED=/c\LINKFORSHARED=' Makefile
    make $MAKEOPTS >>python.log 2>&1
    pushd Lib >/dev/null
    zip -r $INITRAMFS_DIR/lib/python35.zip . >>python.log 2>&1
    popd >/dev/null
    cp -p python $INITRAMFS_DIR/bin
    chmod +x $INITRAMFS_DIR/bin/python
    popd >/dev/null
}

function build_busybox {
    echo "Downloading and extracting Busybox $BUSYBOX_VER..."
    download_and_verify $BUSYBOX_URL $BUSYBOX_SHA1
    tar -xf "$DOWNLOAD_DIR/$(basename $BUSYBOX_URL)"

    pushd busybox-* >/dev/null
    echo "Building Busybox $BUSYBOX_VER..."
    make defconfig >>busybox.log 2>&1
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    make $MAKEOPTS >>busybox.log 2>&1
    cp -p busybox $INITRAMFS_DIR/bin
    chmod +x $INITRAMFS_DIR/bin/busybox
    popd >/dev/null
}

function build_kernel {
    echo "Downloading and extracting kernel $KERNEL_VER..."
    download_and_verify $KERNEL_URL $KERNEL_SHA1

    echo "Building kernel $KERNEL_VER..."
}

function create_initramfs {
    pushd $INITRAMFS_DIR >/dev/null
    echo "Creating initramfs..."
    find . -print0 | cpio --null -ov --format=newc | gzip > $SOURCE_DIR/initramfs.gz
    popd >/dev/null
}

set -e

preseed_initramfs
build_python
build_busybox
build_kernel
create_initramfs

echo "Done. An initramfs is located at $SOURCE_DIR/initramfs.gz"
