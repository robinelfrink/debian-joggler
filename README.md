# Debian for the Joggler

This is used to create a base [Debian Stretch](https://www.debian.org/) image for
the [O2 Joggler](https://en.wikipedia.org/wiki/O2_Joggler).

## Requirements

A computer running Linux, having `debootstrap`, `mount`, `parted`, `coreutils`
and `xz-utils` installed.

## Creating the image

Clone this repository, and run:

    $ ./build.sh

The script uses sudo, so it will ask for your password.

When the script is ready, you will find a `joggler.img.xz` which, when
extracted, will result in a 2GB disk image which you can write to an
USB stick.

## Write to USB stick

Assuming your USB stick is known as `/dev/sdc`, and it is not currently
mounted, run:

    $ xz -dvvc joggler.img.xz | sudo dd of=/dev/sdc bs=1M

## Using it

When the Joggler has booted up, it will have (tried to) get an IP address
using DHCP. You can ssh into the joggler using the username `joggler` with
password `joggler`. This user is part of the `sudo` group.

## Notes

* A patched version of grub has been used, because of
  [kernel relocation issues](http://wuffcode.wolfpuppy.org.uk/2012/01/joggler-improving-grub.html).
  This specific grub binary has been taken from
  [Jools Wills' Ubuntu image](https://jwills.co.uk/projects/joggler-xubuntu/).
* A script is in use to generate a MAC address for the ethernet device. This
  script has been taken from [Andrew Davison's repository](https://github.com/andydvsn/OpenFrame-Ubuntu/).

## To do

* Try to get the kernel booted using an unpatched EFI bootloader available
  in Debian.
* Investigate if there's really no sign of a MAC address to use for the
  ethernet device in the firmware.
* Find out why the GMA500 driver is oopsing the kernel, and see if it can be
  prevented by either some kernel parameters or a patch.
* Build a kernel incorporating some or all of the patches found at
  [Andrew's site](http://birdslikewires.co.uk/download/openframe/kernel/).
* Build a kernel optimised for the Joggler. Remove ISA, floppy, HDMI etc.

