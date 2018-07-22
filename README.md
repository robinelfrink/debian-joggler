# Debian for the Joggler

This is used to create a base [Debian Stretch](https://www.debian.org/) image for
the [O2 Joggler](https://en.wikipedia.org/wiki/O2_Joggler).

## Requirements

A computer running Linux, having `ansible`, `debootstrap`, `mount`, `parted`,
`coreutils` and `xz-utils` installed.

## Creating the image

```bash
$ ansible-playbook build.yml [-e kernel=<version>] [-e gma500=true]
```

The playbook uses sudo, so it will ask for your password.

When the playbook is ready, you will find a `joggler.img.xz` which, when
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

I use qemu for testing some things. In the folder [qemu/](qemu/) you will
find a small disk image `internal.img`, representing the internal disk of
the Joggler, which is needed to make the EFI firmware see our image as `FS1:`.
There is also a binary copy of the 32-bit EFI firmware from the
[EDK II](https://github.com/tianocore/edk2)-project, taken from
[here](https://github.com/BlankOn/ovmf-blobs).

Also in that folder is a helper-script `qemu.sh` which saves me from having
to copy-and-paste the command every time.

Run:

    ./qemu/qemu.sh

This will get you a system booting from the disk image, accessible with SSH at
`localhost`, port 22. There's a lot more options to try with qemu to get the
emulated machine as close to the Joggler as possible, but this will do for now.

## Notes

* A script is in use to generate a MAC address for the ethernet device. This
  script has been taken from [Andrew Davison's repository](https://github.com/andydvsn/OpenFrame-Ubuntu/).
* The `gma500_gfx` has been disabled on boot by default, because the Joggler
  will result in a kernel panic when loaded and no proper patches have been
  applied. See [here](kernel/) if you want to use a patched kernel.

## To do

* Build a kernel optimised for the Joggler. Remove ISA, floppy, HDMI etc.
