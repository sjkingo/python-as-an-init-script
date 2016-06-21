# python-as-an-init-script

Proof-of-concept that you can run Python as a Linux init script (instead of `systemd`, for instance).

## Why?

Just because I thought it would be cool. It's probably not very useful.

## Requirements

There is a fair amount of leg work to be done before booting a kernel. We need to build:

* a custom Python that is statically-linked (scripts use 3.5.1)
* an initramfs containing the requirements for Python and some binary files
* a minimal Linux kernel (though you should be able to run any kernel with the correct architecture)

## Proof

```
[    0.000000] Linux version 4.6.2 (sam@~~~~) (gcc version 5.3.1 20160406 (Red Hat 5.3.1-6) (GCC) ) #1 SMP Sun Jun 19 14:49:13 AEST 2016
[    0.000000] Command line: console=ttyS0
[snip]
[    0.764329] Unpacking initramfs...
[snip]
Python 3.5.1 (default, Jun 20 2016, 14:08:43)
[GCC 5.3.1 20160406 (Red Hat 5.3.1-6)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> 
```
