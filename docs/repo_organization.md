# Repository organization

There are 4 main folders:

- *raspi4_config/*: contains the configuration files, the files
  that are copied in the final image of the OS filesystem and
  some helper scripts needed for the build and which are not
  already provided by Buildroot;
- *raspi4_build/*: is the build directory where Buildroot compiles
  the packages and save the final image of the OS filesystem;
- *buildroot/*: is the git repository of Buildroot;
- *docs/*: is the documentation of the project.

## raspi4_config/

Buildroot consists of several phases. It starts from the download and
compilation of the tools used by the host system and then it moves to
the download and cross-compilation of the packages and Linux kernel for
the target device.

There are two moments where one can add some custom steps by running some
scripts: one is between the compilation and the build of the final
filesystem image and one is after the creation of the filesystem image.
The first one is very useful in case you want to include
packages or configurations which are not expected by Buildroot.

The *raspi4_config* contains all the files and folders used by Buildroot.

### Description of the content

- *buildroot_config*: this is the configuration of Buildroot. This is loaded
  to the buildroot/ folder before running make on Buildroot.
- *overlay/*: this folder contains the files copied in the root filesystem
  before packing everything in the .img file. This folder is merged with
  the root filesystem folder, so the files in it must respect the same
  folder structure of the root filesystem.
- *device_table.txt*: this describes the permissions and owner of the
  files in the root filesystem. For this project it is used to set the
  right permissions to the files in *overlay/*.
- *add_rpi_custom_config.sh*: this script overwrites the file
  *raspi4_build/images/rpi-firmware/config.xml*.
  This is the configuration file used by the Raspberry CPU to configure the
  hardware before loading the Linux kernel. The overwritten file adds
  the information for the kernel to load the fragment of the DTB
  responsible for reconfiguring the USB-C port as a network device.
- *user_table.txt*: this file describes the users to be created in the
  system.
- *influxdb_install.sh*: this script is called when Buildroot finishes
  compiling all his stuff and before packing the image. This script
  downloads and installs InfluxDB into the final filesystem.
- *telegraf_install.sh*: this script follows the one for InfluxDB. It
  downloads and installs Telegraf.
- *grafana_install.sh*: this script follows the previous one during the
  build process. It downloads and installs Grafana in the system. It also
  configures it to connect to InfluxDB and it adds a premade dashboard
  to display the system parameters.

## raspi4_build/

This folder is the build directory of Buildroot. All the compilations
happen here. You can also find here the toolchain used to cross compile
the packages. You can use it to cross compile anything even outside
Buildroot. The toolchain is under *host/bin/*

The cross compiled packages are under the *build/* folder. The *target/*
folder is the what will become the **root filesystem**. Here you can see
the root folder structure. If you want to add a file which will then
appear in the filesystem you can add it here. The *images/* folder is
the output of the Buildroot execution. Here you have the binary images
of the SD card partitions and the files needed to boot the CPU of the
Raspberry (under *rpi-firmware*).

Finally in this folder there's also the real config file used by Buildroot.
It is called *.config* and normally is a copy of the *buildroot_config*
file in the *raspi4_config/* folder.

## buildroot/

This folder is the official git repository of Buildroot.

It is cloned by the *compile_buildroot.sh* script and a specific tag or
commit is checked out to make sure all the compilations are equal and
don't depend on the version of Buildroot used.

When Buildroot downloads the packages it puts them here, under the *dl/*
folder. You can delete the *raspi4_build/* folder and next time you build
the system you won't download all the packages again because they are
stored here.

## docs/

In this folder there's the documentation for this project.
You can go back to the main page by clicking [here](README.md).
