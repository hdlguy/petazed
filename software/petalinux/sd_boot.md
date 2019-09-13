# Petalinux on Zed

This document describes how to boot Ubuntu Linux from the SD card, on the Avnet Zed Board.

### Download and install Xilinx Petalinux 2019.1. 

See "PetaLinux Tools Documentation Reference Guide", (UG1144).  The installer can be downloaded here. It is about 7 GB.

    https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2019.1-final-installer.run

Xilinx recommends you install Petalinux in a folder you control, for example ~/xilinx/petalinux

Note: There is an error in the installation instructions for Ubuntu. You need to install the gawk package not awk.

Note: Petalinux is picky about the Linux version you are running. Check UG1144.

### Set up your environment variables. 

Run something like this depending on where you installed Petalinux.

    source ~/xilinx/petalinux/settings.sh

### Download the the Petalinux BSP for the Zed Board.

    https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html

    It is called "avnet-digilent-zedboard-v2019.1-final.bsp". It is about 1.2 GB. Put it somewhere it can be accessed in the next command.


### Create a petalinux project from the Zed BSP.

    petalinux-create --force --type project --template zynq --source ~/Downloads/xilinx/zed/avnet-digilent-zedboard-v2019.1-final.bsp --name proj1

  You will get a new folder called proj1.

### Configure the project.  

This runs a "make config" style graphical menu.

    cd proj1

    petalinux-config --get-hw-description=../../../fpga/implement/results/

This will bring up a configuration menu.  Make the following changes.

    * Under "Image Packaging Configuration" -> 
        "Root filesystem type" -> 
        Select "SD Card"

    * Under "Subsystem AUTO Hardware Settings" ->
        "Advanced bootable images storage Settings" ->
            "u-boot env partition settings" ->
                "image storage media" ->
                    Select "primary sd"

    * Under "DTG Settings" -> (I don't know if we need to modify bootargs.)
        "Kernel Bootargs" -> 
        Un-select "generate boot args automatically" -> 
        Enter "user set kernel bootargs" -> Paste in the following line
            earlycon clk_ignore_unused earlyprintk root=/dev/mmcblk0p2 rw rootwait cma=1024M

    * Save and exit the configuration menu. Wait for configuration to complete.

### Build the bootloader

    petalinux-build -c bootloader -x distclean

### Run another configu menu.

    petalinux-config -c kernel

    You don't need to change anything. Just exit.

### Build the linux kernel

    petalinux-build

    It takes a while to run.

### create the boot files that u-boot expects. 

    petalinux-package --force --boot --fsbl images/linux/zynq_fsbl.elf --u-boot images/linux/u-boot.elf

    BOOT.BIN contains the ATF, PMUFW, FSBL, U-Boot.
    image.ub contains the device tree and Linux kernel.

### Copy the boot files to the SD card.

    cp images/linux/BOOT.BIN /media/pedro/BOOT/
    cp images/linux/image.ub /media/pedro/BOOT/

    It is assumed that you already partitioned the SD card. 
    - sudo gparted  (make sure you have the correct drive selected!)
    - First partition called BOOT, FAT32, 512MB
    - Second partition called rootfs, ext4, use the rest of the card.

### Root Filesystem

#### Download

    cd ..
    wget https://releases.linaro.org/debian/images/developer-armhf/latest/linaro-stretch-developer-20170706-43.tar.gz

#### Uncompress the root filesystem (preserving file attributes and ownership)

    sudo tar --preserve-permissions -zxvf linaro-stretch-developer-20170706-43.tar.gz

#### Copy the root filesystem onto the SD card preserving file attributes and ownership.

    sudo cp --recursive --preserve binary/* /media/pedro/rootfs/ ; sync

### Boot


- Eject the SD card from your workstation and install it in the ZCU104.

- Connect to the USB Uart port on the zcu104 and start a terminal emulator. I use screen sometimes.

    sudo screen /dev/ttyUSB1 115200

- Power on the board and watch the boot sequence. U-boot will time out and start linux. You should end up at the command prompt as root.

    If you connect an ethernet cable to your network you should be able to update the OS with

    apt update
    apt upgrade

- You can start installing things.

    apt install man
    apt install subversion

- It is a good idea to create a user for yourself and give it sudoer privileges.

    adduser myuser
    usermod -aG sudo myuser

- The serial  terminal is limiting so I like to ssh into the board. First, find the ip address of the zcu104.

    ifconfig (or "ip address")

    Then go back to your workstation.

    ssh myuser@<ip address> 

- This is a good time to update the OS. This takes about 10 minutes the first time.

	sudo apt update
	sudo apt upgrade

- Also there is a problem with the linux command priviledges so you probably need this.

    sudo chmod u+s /bin/*


- Configure the PL side of the Zynq with an FPGA design. This has changed with this newer Linux on Zynq+.

    Modify your FPGA build script to produce a .bin file in addition to the normal .bit file. The FPGA example in this project has that command in compile.tcl.
    
    Go to your terminal on the Zynq+ Linux command line.

    Do a "git pull" to get the latest .bin file from the FPGA side of the repo.

    Copy .../fpga/implement/results/top.bit.bin to /lib/firmware. I think you need to do this as sudo.

    Change to root with "sudo su".

    echo top.bit.bin > /sys/class/fpga_manager/fpga0/firmware

    This last command should make the "Done" LED go green indicating success.

- Good luck.
