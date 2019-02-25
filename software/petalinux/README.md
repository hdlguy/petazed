Here we save the condensed instructions to create a petalinux image for booting from the QSPI. Everything here is taken from Xilinx UG1144.

This assumes Petalinux is installed correctly. (Warning: Xilinx FPGA tools run on Ubuntu 18.04 LTS but Petalinux requires 16.04 LTS.)

- First create a petalinux project from the Zed BSP.  You will get a new folder called proj1.

    petalinux-create --force --type project --template zynq --source ~/Downloads/xilinx/zed/avnet-digilent-zedboard-v2018.3-final.bsp --name proj1

- Now lets configure the project.  This runs a "make config" style graphical menu.

    cd proj1

    petalinux-config --get-hw-description=../../../fpga/implement/results/

- In the graphical menu make the following changes to boot from QSPI flash.

    - Select Subsystem AUTO Hardware Settings.
        - Select Advanced Bootable Images Storage Settings.
            - Select **boot** image settings.
                - Select Image Storage Media.
                - Select boot device as primary flash.
            - Select **kernel** image settings.
                - Select Image Storage Media.
                - Select the storage device as primary flash.

- Now build the bootloader

    petalinux-build -c bootloader -x distclean

- Now run another configu menu.

    petalinux-config -c kernel
    
    You don't need to change anything. Just exit.

- Now build the linux kernel

    petalinux-build

    It takes a while to run.

- Now create the boot BOOT.BIN file that u-boot expects. 

    petalinux-package --boot --force --fsbl --u-boot --kernel --fpga ../../../fpga/implement/results/top.bit

    Now BOOT.BIN contains the FSBL, U-Boot, device tree, Linux kernel and minimal root filesystem.

- Now burn the BOOT.BIN into the QSPI flash. 
    - Set the jumpers JP3, JP2 and JP1 to up, up, up. This puts the board into JTAG boot mode. (Note: the board won't boot from QSPI in this mode.)
    - Open Vivado Hardware Manager and connect to the target.
    - Add the QSPI flash memory. Its an S25FL, 3.3V, 4 bits wide.
    - Add .elf file for the FSBL and the BOOT.BIN as the programming file.
    - Select program device and check erase, program and verify.
    - Burn QSPI.
    - Set the jumpers for QSPI boot mode, down, up, up.

- Boot the OS
    - Connect to the usb-uart of the board using a terminal emulator, putty, screen, minicom or similar.
    - Settings are 115200 baud, 8-1-none.
    - Hit the reset button and watch for text. First, u-boot starts. You can stop in u-boot by hitting any key.
    - After a timeout u-boot will start the linux kernel.  The petalinux-configure command creates the right boot command to 
      point to the ram filesystem, etc.






