# Petalinux Development Cheatsheet

These instructions are for Petalinux 2022.1.

## Petalinux Build Project

Create the petalinux project. 

    petalinux-create --force --type project --template zynq --source ./uzed.bsp --name proj1

Configure the petalinux project with the settings we need to run Ubuntu from the SD card.

    cd proj1

    petalinux-config --get-hw-description=../../../fpga/implement/results/

This will bring up a configuration menu.  Make the following changes. These changes will automatically be incorporated into the Petalinux build based on the BSP.

    * Under "Image Packaging Configuration" -> "Root filesystem type" -> Select "SD Card"

    * Save and exit the configuration menu. Wait for configuration to complete.

### Build the bootloader

    petalinux-build -c bootloader -x distclean

Run another configu menu.

    petalinux-config -c kernel --silentconfig

### Build the linux kernel

    petalinux-build

It takes a while to run.

### Create the boot files that u-boot expects.

    petalinux-package --force --boot --fsbl --u-boot --fpga ../../../fpga/implement/results/top.bit

BOOT.BIN contains the ATF, PMUFW, FSBL, U-Boot.
image.ub contains the device tree and Linux kernel.

### Copy the boot files to the SD card.

    cp images/linux/BOOT.BIN /media/pedro/BOOT/
    cp images/linux/image.ub /media/pedro/BOOT/
    cp images/linux/boot.scr /media/pedro/BOOT/

It is assumed that you already partitioned the SD card.
- sudo gparted  (make sure you have the correct drive selected!)
- First partition called BOOT, FAT32, 512MB
- Second partition called rootfs, ext4, use the rest of the card.

## Get the Root Filesystem

Download the root filesystem. It is 360MB.

    wget https://releases.linaro.org/debian/images/developer-armhf/latest/linaro-stretch-developer-20170706-43.tar.gz

Uncompress the root filesystem preserving file attributes and ownership.

    sudo tar --preserve-permissions -zxvf linaro-stretch-developer-20170706-43.tar.gz

Copy the root filesystem onto the SD card preserving file attributes and ownership.

    sudo cp --recursive --preserve binary/* /media/pedro/rootfs/; sync

Eject the SD card from your workstation and install it in the eval board.

## Boot the Board

Connect to the USB uart port on the eval board and start a terminal emulator. I use screen sometimes.

    sudo screen /dev/ttyUSB1 115200
or
    sudo putty

Power on the board and watch the boot sequence. U-boot will time out and start linux. You should end up at the command prompt as root.

    If you connect an ethernet cable to your network you should be able to update the OS with

    apt update
    apt upgrade

You can start installing things.

    apt install man
    apt install subversion

It is a good idea to create a user for yourself and give it sudoer privileges.

    adduser myuser
    usermod -aG sudo myuser

The serial  terminal is limiting so I like to ssh into the board. First, find the ip address of the zcu104.

    ifconfig (or "ip address")

    Then go back to your workstation.

    ssh myuser@<ip address>

## Configure the FPGA Fabric

Configure the PL side of the Zynq with an FPGA design. This has changed with this newer Linux on Zynq+.

    Modify your FPGA build script to produce a .bin file in addition to the normal .bit file. The FPGA example in this project has that command in compile.tcl.

    Go to your terminal on the Zynq+ Linux command line.

    Do a "git clone" or "git pull" to get the latest .bin file from the FPGA side of the repo.

    Copy .../fpga/implement_p2/results/top.bit.bin to /lib/firmware. I think you need to do this as sudo. You may have to create /lib/firmware and chmod to 777.

    Change to root with "sudo su".

    echo top.bit.bin > /sys/class/fpga_manager/fpga0/firmware

    This last command should make the "Done" LED go green indicating success.

- Good luck.

