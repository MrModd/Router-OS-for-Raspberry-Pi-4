# Router OS for Raspberry Pi 4

![Router OS](docs/images/router_os.png)

Router OS is a Linux distribution for Raspberry Pi 4.
It is a custom build assembled using [Buildroot](https://buildroot.org/).

The purpose of this operating system is to provide a lightweight and
minimalistic Linux distribution to make the Raspberry into a network router.

There are three main key point behind this project:

- Provide a **read only root filesystem** with a RW overlay
  which makes the board safe to unplug in any moment
- Provide a **default configuration** which allows to connect
  to the board via a WiFi network to make further changes (all headless)
- Provide a **configuration tool** to setup the board as a
  router between two wireless networks or a wireless network and a
  wired one.

## Getting Started

To get ready all you need to do is to build the filesystem image which
will go to the MicroSD card for the Raspberry Pi.

### Prerequisites

The only requirements are to be able to run Buildroot.
For this I invite you have a look at the
[Buildroot requirements](https://buildroot.org/downloads/manual/manual.html#requirement)
section of the documentation.

### Building the image

To build the filesystem image run the script `compile_buildroot.sh` with
no arguments.
Follow the output of the script and answer to the questions if
needed (always press Enter when in doubt ;P).

The compilation will take some time. Probably more than 30 mins.

If everythig goes well you'll find the output of the compilation
in the folder *raspi4_build/images/*.
The file *boot.vfat* is the dump of the first vfat partition and
the file *rootfs.ext2* is the dump of the second ext4 partition.
There's also the file *sdcard.img* which is the dump of the entire
SD card.

### Installing

The easiest way to get the OS into a microSD card is to copy the content
of *sdcard.img* directly into the block device of the memory card.
For example (to run as root user or using sudo):

`dd if=./raspi4_build/images/sdcard.img of=/dev/sdX bs=2M`

**/!\ This command will erase all the content of the device!**

Run it only when you are confident on what you are doing.

In the example *sdX* is the device which represent your SD card.
You can discover the right letter by checking the output of the
command `lsblk`.

### Connecting to the system

Once the image is on the SD card instert it in the Raspberry and power
it on. You can then connect to it using one of the many intefaces
available:

- **WiFi**: the default image turns the internal WiFi network card into
  an Access Point. The name of the network is **Routerberry**. There's
  no security, you can connect without password (or any other kind of
  authentication).
- **Ethernet**: connect an Ethernet cable to the Eth port of the Raspberry
  and you'll get an IP from the DHCP server.
- **USB-C to Eth**: power the Raspberry using an USB-C data cable and plug
  it into your computer and you'll see a new network device. Enable it
  and you'll automatically get an IP from the DHCP server.
- **UART** (more advanced): connect a Serial-to-USB adapter to your
  computer and connect the pins GND, TXD and RXD to the pins 6, 8 and 10
  (respectively) of the 40 pins expansion header of the Raspberry (more
  info [here](https://www.raspberrypi.org/documentation/usage/gpio/)).
  Then use the tool you prefer to communicate with the serial port (for
  example `minicom`).

Default login is:

- user: `admin`
- password: `admin`

You can use `sudo` to perform root operations.

### Documentation

All the documentation is in the [docs](docs/README.md) folder.

## Built With

* [Buildroot](https://buildroot.org/) - The tool used to create the
  embedded Linux system

## Versioning

The stable releases are published in the **master** branch of this
repository. All the experimental features are in the **develop** branch.

The milestones are marked with a **tag**.

## Authors

* **Federico Cosentino** - [MrModd](https://bitbucket.org/MrModd/)

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See the [COPYING](COPYING) file for details
or go to <https://www.gnu.org/licenses/>.

## Acknowledgments

I copied some of the scripts or parts of them from other Open Source
projects. If I'm not the author of the code you will find information
on the detentor of the rights in the first section of the files.
