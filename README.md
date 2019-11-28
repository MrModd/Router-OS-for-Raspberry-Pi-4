# Buildroot OS for Raspberry Pi 4

This repository aims to build a Linux based operating system
from scratch using Buildroot.

Main features of this OS are:

- Provide a **read only root filesystem** with a RW overlay
  which makes the board safe to unplug in any moment
- Provide a **default configuration** which allows to connect
  to the board via a WiFi network to make further changes (all headless)
- Provide a **configuration tool** to setup the board as a
  router between two wireless networks or a wireless network and a wired one.

## Rationale

Boards like the Raspberry Pi or the ODROID are becoming more and
more popular thanks to their computational power.
Nowadays they are powerful enough to satisfy the needs of most of
the users. It's very straightforward to download and install a
GNU/Linux distribution and to start using the system for browsing
or video playback.

*Straightforward means boring...*

I've always been fascinated by the operating systems of network
devices such as routers.
Their sturdy filesystem let you unplug the power at any time
without any damage. If for some reason the configuration gets
corrupted you can simply reset the device to restore the
*factory parameters* and you are again good to go.

**How to achieve this?**

In one word: *overlaying*

The root filesystem is made of the union of two or more filesystems
(or more in general folders). We will call those filesystem **layers**.
One layer is made **read only** and it contains a basic linux installation.
A full root scheleton with all the binaries, config files and libraries.
This by itself works and makes the device boot.
All the customization are stored in another **read write** layer.
This second layer can be in memory (meaning all the changes are lost
after every power cycle) or on a different block device. The drawback
of this second choice is that it can get corrupted if you unplug the
power while the system is writing here. In this case you can always
wipe the second layer to go back to the default configuration.

## Project description

The idea of this project is to play with the overlay filesystem
applying it on a real use case.
The goal is to transform the Raspberry Pi 4 in a router with the
following features:

- Isolation between two distinct networks with a NAT and a firewall
- Ability to easily configure the topology (e.g. NAT or bridge)
- A basic configuration that let users easily access to the system
  to perform the initial configuration

The basic configuration is done by setting the integrated wireless
network interface of the Raspberry Pi 4 as a hosted mode so that
other devices can connect to it.
Once connected a user can ssh to the Raspberry to launch the
config tool and set up the desired configuration.

Note that at least two network devices are required. They can be
either the integrated WiFi and Ethernet or another USB device.

This project doesn't start from a premade GNU/Linux distribution,
but rather it uses **Buildroot** to assemble an entire custom
operating system by picking up by hand EVERYTHING. Starting from
the toolchain for the cross compilation to the way to assemble
the root filesystem scheleton.

## Milestones

This project is developed with some milestone in mind.

1. Basic GNU/Linux OS made starting from the default configuration
   of Buildroot
2. GNU/Linux OS with the basic routing configuration (DHCP, Wireless
   access point)
3. Same image as previous step, but with tools to customize the
   configuration at runtime
4. Filesystem overlaying to make the changes appear only on the
   upper overlay RW filesystem
5. (Optional) basic driver for external GPIO interface to perform
   some basic operations such as reboot, factory reset, Wireless
   ON/OFF

## How to use

Buildroot is a fantastic tool all centered on the use of make.
It automates the fetch of all the packages, it downloads as well
the Linux kernel and the toolchain for the cross compilation.
You can learn more about Buildroot by checking the official
website. [Link here](https://buildroot.org/).

The script **"compile_buildroot.sh"** is a wrapper on top of Buildroot.
The feature it has are the following:

- It clones and updates the buildroot repository if not present
- It keeps automatically the configuration folder and the build
  folder separated
- It calls Buildroot with all the required variables (such as
  the one which specifies where the build folder is)
- It manages the load and save of the configuration file

About this last point the reason is that the configuration
file used by Buildroot is the file ".defconfig" that must be
present in the base directory of Buildroot itself (as it happens
for the Linux kernel source code).
The script "compile_buildroot.sh" takes care of saving
the current configuration of Buildroot in the external
folder and of loading inside the Buildroot folder the
previously saved configuration.

### Usage of "compile_buildroot.sh"

To compile everything simply call the script: `./compile_buildroot.sh`.
If it is the first time you run it it will download Buildroot as well.
At the question "Load the buildroot config file? [Y|n]" say yes
otherwise it will fail because there isn't a default configuration
on a freshly downloaded copy of Buildroot.

With -h you can check the arguments you can give to the script.
If you want to know the arguments you can give to Buildroot
call the script with `./compile_buildroot.sh help`. This will
invoke the `make help` target of Buildroot.

### Folder structure

There are three main folders:

- *raspi4_config/*: contains the configuration file, the files
  that are copied in the final image of the OS filesystem and
  some helper scripts needed for the build and which are not
  already provided by Buildroot;
- *raspi4_build/*: is the build directory where Buildroot compiles
  the packages and save the final image of the OS filesystem;
- *buildroot/*: is the git repository of Buildroot.

### Getting started

This section should be on the top, isn't it?

First build the image with `./compile_buildroot.sh`.
Follow the output of the script and answer to the question if
needed.
The compilation will take some time. Probably more than 15 mins.
If everythig goes well you'll find the output of the compilation
in the folder *raspi4_build/images/*.
The file *boot.vfat* is the dump of the first vfat partition and
the file *rootfs.ext2* is the dump of the second ext4 partition.
There's also the file *sdcard.img* which is the dump of the entire
SD card.

The easiest way to get it is to copy the content of sdcard.img
directly into the block device of the microSD.
An example is this:

`dd if=raspi4_build/images/sdcard.img of=/dev/sdd bs=2M`

To run as root (or with sudo).
In this case the SD card is mapped to the /dev/sdd device.
