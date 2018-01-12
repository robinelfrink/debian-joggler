# Debian for the Joggler

This is used to create a base [Debian Stretch](https://www.debian.org/) image for
the [O2 Joggler](https://en.wikipedia.org/wiki/O2_Joggler).

## Requirements

A computer running Linux, having `debootstrap`, `mount`, `parted`, `coreutils`
and `xz-utils` installed.

## Creating the image

    Usage: ./build.sh [OPTION]...
    Create Debian Stretch image for the O2 Joggler.
    
    -s, --size SIZE    Total size of the image in MB, defaults to 2000
    -h, --help         Display this help and exit

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

## Testing

I use qemu for when testing some things. In the folder [qemu/](qemu/) a small
disk image `internal.img`, representing the internal disk of the Joggler so
our image is really seen as `FS1:`, and a binary copy of the 32-bit EFI
firmware from the [EDK II](https://github.com/tianocore/edk2)-project, taken
from [here](https://github.com/BlankOn/ovmf-blobs).

Run:

    qemu-system-i386 -bios qemu/bios32.bin -usb -device nec-usb-xhci,id=xhci \
        -drive if=none,format=raw,id=internal,file=qemu/internal.img \
        -device usb-storage,bus=xhci.0,drive=internal \
        -drive if=none,format=raw,id=external,file=joggler.img \
        -device usb-storage,bus=xhci.0,drive=external \
        -m 512M -k en-us -monitor stdio \
        -net nic,model=rtl8139 \
        -net user,net=10.255.0.0/24,dhcpstart=10.255.0.10,hostfwd=tcp::1222-:22 \
        -cpu n270

This will get you a system booting from the disk image, accessible with SSH at
`localhost`, port 22. There's a lot more options to try with qemu to get the
emulated machine as close to the Joggler as possible, but this will do for now.

## Notes

* A script is in use to generate a MAC address for the ethernet device. This
  script has been taken from [Andrew Davison's repository](https://github.com/andydvsn/OpenFrame-Ubuntu/).

## To do

* Investigate if there's really no sign of a MAC address to use for the
  ethernet device in the firmware.
* Find out why the GMA500 driver is oopsing the kernel, and see if it can be
  prevented by either some kernel parameters or a patch.
* Build a kernel incorporating some or all of the patches found at
  [Andrew's site](http://birdslikewires.co.uk/download/openframe/kernel/).
* Build a kernel optimised for the Joggler. Remove ISA, floppy, HDMI etc.

