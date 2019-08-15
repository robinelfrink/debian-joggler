#!/bin/sh

SCRIPT=$0
ROOT=$(readlink -f $(dirname $(readlink -f ${SCRIPT}))/../)

qemu-system-i386 -bios qemu/bios32.bin \
    -machine pc -cpu n270 \
    -m 512M -usb -k en-us -monitor stdio \
    -device VGA \
    -device pci-bridge,id=pci_bridge1,chassis_nr=1 \
    -device rtl8139,netdev=nic1,bus=pci_bridge1,addr=1 \
    -device usb-storage,drive=internal \
    -device usb-storage,drive=external \
    -usbdevice tablet \
    -drive if=none,format=raw,id=internal,file=${ROOT}/qemu/internal.img \
    -drive if=none,format=raw,id=external,file=${ROOT}/joggler.img \
    -netdev user,id=nic1,net=10.255.0.0/24,dhcpstart=10.255.0.10,hostfwd=tcp::1222-:22
