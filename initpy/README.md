# initpy - a Linux init system using Python

1. Download latest stable kernel and extract (you may need `ncurses-devel` first):

      $ wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.6.2.tar.xz
      $ tar -xf linux-4.6.2.tar.xz
      $ cd linux-4.6.2
      $ cp initpy/linux-config-4.6.2 .config
      $ make -j7
