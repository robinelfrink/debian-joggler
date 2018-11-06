# Debian for the Joggler

This is used to create a base [Debian Stretch](https://www.debian.org/) image for
the [O2 Joggler](https://en.wikipedia.org/wiki/O2_Joggler).

## For the impatient

Ready-to-use images, with a custom kernel and the gma500 driver enabled,
are available at the
[releases overview](https://github.com/robinelfrink/debian-joggler/releases).

Download the release you want, and (assuming your USB stick is known as
`/dev/sdc`) run:

    $ xz -dvvc debian-joggler-<release>.img.xz | sudo dd of=/dev/sdc bs=1M

## Requirements

A computer running Linux, having `ansible`, `debootstrap`, `mount`, `parted`,
`coreutils` and `xz-utils` installed.

## Creating the image

```bash
$ ansible-playbook build.yml [-e variable=value] [-e ...]
```

The optional extra variables are documented below.

The playbook uses sudo, so it will ask for your password.

When the playbook is ready, you will find a `joggler.img.xz` which, when
extracted, will result in a 2GB disk image which you can write to an
USB stick.

## Extra variables

* `kernel=<version>`

  Install kernel version <version> instead of the default Debian kernel. The
  playbook looks for the `linux-image-<version>_i386.deb`-file in
  `./kernel`.

* `gma500=true`

  Enable the `gma500_gfx` module to get accelerated graphics. You need a
  patched kernel for this.

* `usetarball=true`

  Use a tarball (`packages.tgz`) to extract packages from, instead of
  downloading them. If the tarball does not exist, it will be created first.

* `enable_sleep=true`

  Enable sleep (and suspension).

* `disable_brightnessd=true`

  Do not install brightnessd.

* `timezone=<timezone>`

  Set the Joggler's timezone, e.g. 'Europe/Amsterdam'

* `add_jivelite=true`

  Install JiveLite, and make it start automatically on boot.

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

This will get you a system booting from the (uncompressed) disk image,
accessible with SSH at localhost`, port 1222. There's a lot more options to try
with qemu to get the emulated machine as close to the Joggler as possible, but
this will do for now.

## Notes

* A script is in use to generate a MAC address for the ethernet device. This
  script has been taken from [Andrew Davison's repository](https://github.com/andydvsn/OpenFrame-Ubuntu/).
* The `gma500_gfx` has been disabled on boot by default, because the Joggler
  will result in a kernel panic when loaded and no proper patches have been
  applied. See [here](kernel/) if you want to use a patched kernel.

## To do

* Build a kernel optimised for the Joggler. Remove ISA, floppy, HDMI etc.
