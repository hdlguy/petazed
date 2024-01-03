# Petalinux Development Cheatsheet

These instructions are for Petalinux 2022.1.

## Petalinux Build Project

petalinux-create --force --type project --template zynq --name proj1

cd proj1

petalinux-config --get-hw-description=../../implement/results/

    * Yocto Settings -> Add pre-mirror url -> change http: to https:
    * Yocto Settings -> Network State Feeds url -> change http: to https:
    * Image Settings -> EXT4 (if you want the rootfs on the sd card)
    //* Image Packaging Configuration -> Device node of SD device -> mmcblk0p2 (if you have the eMMC device enabled in Vivado IPI)
    //* Subsystem Auto Hardware Settings -> SD/SDIO Settings -> Primary SD/SDIO -> psu_sd_1 (if you have the eMMC device enabled in Vivado IPI)
    * save and exit

petalinux-build -c bootloader -x distclean

petalinux-config -c kernel --silentconfig

petalinux-build

petalinux-package --force --boot --u-boot --kernel --offset 0xF40000 --fpga ../../implement/results/top.bit

cp images/linux/BOOT.BIN /media/pedro/BOOT/
cp images/linux/image.ub /media/pedro/BOOT/
cp images/linux/boot.scr /media/pedro/BOOT/

    It is assumed that you already partitioned the SD card.
    - sudo gparted  (make sure you have the correct drive selected!)
    - First partition called BOOT, FAT32, 512MB
    - Second partition called rootfs, ext4, use the rest of the card.

    Eject the SD card from your workstation and install it in the eval board.

cd ..

## Installing a Debian root filesystem using debootstrap

Then follow instructions here to confgure the root file system: https://akhileshmoghe.github.io/_post/linux/debian_minimal_rootfs

Here are the most important commands listed for convenience. 

    sudo apt install qemu-user-static
    sudo apt install debootstrap

    sudo debootstrap --arch=armhf --foreign buster debianMinimalRootFS
    sudo cp /usr/bin/qemu-arm-static ./debianMinimalRootFS/usr/bin/
    sudo cp /etc/resolv.conf ./debianMinimalRootFS/etc/resolv.conf
    sudo chroot ./debianMinimalRootFS
    export LANG=C

    /debootstrap/debootstrap --second-stage

Add these sources to /etc/apt/sources.list

    deb http://deb.debian.org/debian buster main contrib non-free
    deb-src http://deb.debian.org/debian buster main contrib non-free
    deb http://security.debian.org/ buster/updates main contrib non-free
    deb-src http://security.debian.org/ buster/updates main contrib non-free
    deb http://deb.debian.org/debian buster-updates main contrib non-free
    deb-src http://deb.debian.org/debian buster-updates main contrib non-free

Do some more file system configuration.

    apt update
    apt install locales dialog
    dpkg-reconfigure locales
    apt install vim openssh-server ntpdate sudo ifupdown net-tools udev iputils-ping wget dosfstools unzip binutils libatomic1
    passwd
    adduser myuser
    usermod -aG sudo myuser
    usermod --shell /bin/bash <user-name>

Add to /etc/network/interfaces

    auto eth0
    iface eth0 inet dhcp

Exit chroot.

    exit

Write filesystem to SD card.

    sudo cp --recursive --preserve ./debianMinimalRootFS/* /media/pedro/rootfs/; sync


## Post Boot Stuff

    sudo hostnamectl set-hostname zedboard
    hostnamectl


## Run-time FPGA Configuration

- Configure the PL side of the Zynq with an FPGA design. This has changed with this newer Linux on Zynq+.

Modify your FPGA build script to produce a .bin file in addition to the normal .bit file. The FPGA example in this project has that command in compile.tcl.
    
Go to your terminal on the Zynq+ Linux command line.

Do a "git pull" to get the latest .bin file from the FPGA side of the repo.

cp .../fpga/implement/results/top.bit.bin to /lib/firmware

Change to root with "sudo su".

echo top.bit.bin > /sys/class/fpga_manager/fpga0/firmware

This last command should make the "Done" LED go green indicating success.


## Useful Linux commands

    apt install man
    apt install subversion

    adduser myuser
    usermod -aG sudo myuser

    passwd
