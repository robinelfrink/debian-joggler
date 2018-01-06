#!/bin/sh


SCRIPT=$0
ROOT=`dirname $(readlink -f ${SCRIPT})`


help() {
    echo "Usage: ${SCRIPT} [OPTION]..."
    echo "Create Debian Stretch image for the O2 Joggler."
    if [ -n "$1" ]; then
        echo
        echo "Error: $1"
    fi
    echo
    echo "-s, --size SIZE    Total size of the image in MB, defaults to 2000"
    echo "-h, --help         Display this help and exit"
    echo
    if [ -z "$1" ]; then
        exit 0
    fi
    exit 1
}


# Parse arguments
SIZE=2000M
until [ -z "$1" ]; do
    OPT=$1
    case ${OPT} in
        "-s"|"--size")
            shift
            if [ -z "$1" ]; then
                help "Option ${OPT} needs a value."
            fi
            if ! [ "$1" -eq "$1" ] 2> /dev/null; then
                help "Option ${OPT} requires an integer value."
            fi
            SIZE=$1
            shift
            ;;
        "-h"|"--help")
            help
            ;;
        *)
            help "Unknown option ${OPT}."
            ;;
    esac
done


# Require root privileges
if [ "$UID" != "0" ]; then
    sudo echo -n ''
    if [ "$?" -ne "0" ]; then
        echo 'Root privileges are required'
        exit
    fi
fi


# Unmount
unmount () {
    sudo umount -f ${ROOT}/root/boot ${ROOT}/root/dev/pts ${ROOT}/root/dev ${ROOT}/root/sys ${ROOT}/root/proc ${ROOT}/root
    LOOP=`losetup | grep ${ROOT}/joggler.img | awk '{print($1)}'`
    if [ "${LOOP}" != "" ]; then
        sudo zerofree -v ${LOOP}p2 
        sudo losetup -d ${LOOP}
    fi
}


# Create image
unmount
rm -f ${ROOT}/joggler.img ${ROOT}/joggler.img.xz
truncate -s${SIZE}M ${ROOT}/joggler.img

# Set up partitions
parted -s ${ROOT}/joggler.img mklabel msdos
parted -s -a none ${ROOT}/joggler.img mkpart primary fat16 1 64M
parted -s ${ROOT}/joggler.img set 1 boot on
parted -s -a none ${ROOT}/joggler.img mkpart primary ext4 64M 100%

# Create loop device
LOOP=`losetup -f`
sudo losetup -P ${LOOP} ${ROOT}/joggler.img

# Format partitions
sudo mkfs.fat ${LOOP}p1
sudo fatlabel ${LOOP}p1 'jogglerboot'
sudo mkfs.ext4 -F ${LOOP}p2
sudo e2label ${LOOP}p2 'jogglerroot'

# Mount partitions
mkdir -p ${ROOT}/root
sudo mount -t ext4 -O errors=remount-ro,noatime ${LOOP}p2 ${ROOT}/root
sudo mkdir -p ${ROOT}/root/boot
sudo mount -t vfat ${LOOP}p1 ${ROOT}/root/boot

# Install base system
sudo debootstrap --foreign --arch=i386 --components=main,contrib,non-free --include apt-transport-https,busybox,firmware-misc-nonfree,grub-efi-ia32,initramfs-tools,initramfs-tools-core,klibc-utils,libklibc,linux-base,openssh-server,r8168-dkms,sudo --exclude dmidecode,irqbalance stretch ${ROOT}/root
sudo chroot ${ROOT}/root /debootstrap/debootstrap --second-stage

# Copy /etc/apt/sources.list
sudo cp ${ROOT}/files/sources.list ${ROOT}/root/etc/apt/sources.list
sudo chroot ${ROOT}/root apt-get update

# System mounts
for DIR in dev dev/pts sys proc; do
    sudo mount --bind /${DIR} ${ROOT}/root/${DIR}
done

# Install kernel
sudo chroot ${ROOT}/root apt-get install --assume-yes linux-headers-4.9.0-4-686 linux-image-4.9.0-4-686

# Make bootable
printf "fs1:\ngrub\nfs1:\ngrub\n" | sudo tee ${ROOT}/root/boot/boot.nsh > /dev/null
printf "fs1:\nboot\nfs0:\nboot\n" | sudo tee ${ROOT}/root/boot/startup.nsh > /dev/null
sudo cp ${ROOT}/files/grub.cfg ${ROOT}/root/boot/
sudo chroot ${ROOT}/root grub-mkimage --config /boot/grub.cfg --compression xz --output /boot/grub.efi --format i386-efi --prefix "" configfile fat part_msdos linux boot search search_label efi_gop efi_uga

# Boot in multi-user mode
sudo chroot ${ROOT}/root systemctl set-default multi-user.target

# Copy /etc/fstab
sudo cp ${ROOT}/files/fstab ${ROOT}/root/etc/fstab

# Set hostname
printf "joggler" | sudo tee ${ROOT}/root/etc/hostname > /dev/null
sudo sed -i '1 a 127.0.1.1 joggler' ${ROOT}/root/etc/hosts

# Add user
sudo chroot ${ROOT}/root useradd --home-dir /home/joggler --groups sudo,audio,video --create-home --password sa0dkJX04f4tM --shell /bin/bash joggler

# Configure network interfaces
sudo cp ${ROOT}/files/interfaces ${ROOT}/root/etc/network/
sudo mkdir -p ${ROOT}/root/etc/network/if-pre-up.d
sudo cp ${ROOT}/files/openframe-mac ${ROOT}/root/etc/network/if-pre-up.d/
sudo chmod 755 ${ROOT}/root/etc/network/if-pre-up.d/openframe-mac

# Clean up
sudo rm -f ${ROOT}/var/cache/apt/archives/*.deb
unmount
sudo losetup -d ${LOOP}
sudo rm -rf ${ROOT}/root

# Zip the image
xz -zvv ${ROOT}/joggler.img
