#!/bin/sh


ROOT=`dirname $(readlink -f $0)`


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
rm -f ${ROOT}/joggler.img
truncate -s2G ${ROOT}/joggler.img

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
sudo debootstrap --foreign --arch=i386 --components=main,contrib,non-free --include apt-transport-https,busybox,firmware-misc-nonfree,initramfs-tools,initramfs-tools-core,klibc-utils,libklibc,linux-base,openssh-server,r8168-dkms,sudo,vim --exclude nano stretch ${ROOT}/root
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
sudo cp ${ROOT}/files/grub.efi ${ROOT}/root/boot/
sudo cp ${ROOT}/files/grub.cfg ${ROOT}/root/boot/
sudo cp ${ROOT}/files/unicode.pf2 ${ROOT}/root/boot/

# Boot in multi-user mode
sudo chroot ${ROOT}/root systemctl set-default multi-user.target

# Copy /etc/fstab
sudo cp ${ROOT}/files/fstab ${ROOT}/root/etc/fstab

# Set hostname
printf "joggler" | sudo tee ${ROOT}/root/etc/hostname > /dev/null

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
