# Content of the raspi4_config folder

There are some changes and fixes that are done after Buildroot has finished
compiling and assembling the filesystem.

This folder contains some files that are copied in the final filesystem as
well as some scripts used to make some fixes before the filesystem is packed
in an .img file.

## Description of the content

- buildroot_config: this is the configuration of Buildroot. This is loaded
  to the buildroot/ folder before running make on Buildroot.
- overlay/: this folder contains the files copied in the root filesystem
  before packing everything in the .img file. This folder is merged with
  the root filesystem folder, so the files in it must respect the same
  folder structure of the root filesystem.
- device_table.txt: this file contains the description of the files and
  folders permissions inside overlay/. A chmod to the parameters described
  here is applied when mergin overlay/ with the root filesystem.
- add_rpi_custom_config.sh: this script overwrite the file
  raspi4_build/images/rpi-firmware/config.xml.
  This is the configuration file used by the Raspberry CPU to configure the
  hardware before loading the Linux kernel. The folder rpi-firmware/ is
  generated during the Buildroot compilation of the package rpi-firmware.
  In case this folder is not present check if the rpi-firmware package
  is selected in Buildroot under "Target packages" --> "Hardware handling"
  --> "Firmware". If yes try rebuilding the package with the command
  `./compile_buildroot.sh rpi-firmware-rebuild`.
- user_table.txt: this file describes the users to be created in the
  system.

# How I solved the problems

## Internal WiFi driver

The internal WiFi kernel driver is a module and it must be loaded by
hand during boot.

The right version of the module to use was found
[here](https://www.raspberrypi.org/forums/viewtopic.php?t=138858).

## USB WiFi driver

The USB Wireless card used is a *TP-LINK TL-WN722N* which uses an
**Atheros AR9271** chipsed. In Buildroot these drivers are under the group
of packages "linux-firmware".

How to load the right modules was discovered by plugging the device on a
computer and looking at the new modules that popped out in lsmod.

## USB-C as Ethernet device

The USB-C port, normally used as power input for the Raspberry, can be used
as another network device. The idea came from this
[YouTube](https://www.youtube.com/watch?v=IR6sDcKo3V8) video.

The modules to load were described
[here](https://www.raspberrypi.org/forums/viewtopic.php?t=249877).

The overlay to use was described
[here](https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget/ethernet-gadget).

## Load modules at boot

The way to load modules during boot process
was suggested by
[this](https://unix.stackexchange.com/questions/396542/buildroot-how-to-load-modules-automatically)
post.

It relies to a couple of scripts taken from the "Linux From Scratch" project.
The files used on this project to load the modules are not my property and
they belong to the persons described at the beginning of the files.

## Long boot time

The SSH daemon was taking minutes to boot. The reason was due to the long
wait to get enough entropy to run ssh-keygen.

The solution is to help the kernel collecting the entropy at boot time using
the package rng-tools.

The solution was suggested
[here](https://unix.stackexchange.com/questions/522271/rpi-buildroot-random-crng-init-done-not-enough-entropy-how-to-configure).
