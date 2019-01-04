## Kernel patches and config for the Joggler

Here are the kernel patches and configs I use to build the Linux kernels I
run on my Joggler.

The patches are updated versions of the ones found on
[Andrew's site](http://birdslikewires.co.uk/download/openframe/kernel/).

## How to build

Follow the steps from the Debian Linux Kernel Handbook,
[4.5. Building a custom kernel from Debian kernel source](https://kernel-team.pages.debian.net/kernel-handbook/ch-common-tasks.html#s-common-building).

In short:

```shell
$ wget <url of linux-source-x.x.deb>
$ sudo dpkg -i linux-source-x.x.deb
$ tar xzf /usr/src/linux-source-x.x.tar.xz
$ cd linux-source-x.x
$ cp <location of x.x/config> .config
$ for p in <location of x.x>/*.patch; do patch -p1 < $p; done
$ make oldconfig
$ make deb-pkg
```
