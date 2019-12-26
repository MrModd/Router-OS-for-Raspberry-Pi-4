# The compile_buildroot.sh script

The script **compile_buildroot.sh** is a wrapper on top of Buildroot.
It eases the usage of Buildroot by automating some boring and repetitive
tasks. In particular:

- It clones and updates the buildroot repository if not present and it
  checks out a specific commit/tag/branch;
- It automatically keeps the configuration folder and the build
  folder separated;
- It calls Buildroot with all the required variables (such as
  the one which specifies where the build folder is)
- It manages the load and save of the configuration file

![Buildroot menuconfig(images/buildroot_menuconfig.png)

## Quick reference

- To build the OS image:
  `./compile_buildroot.sh`
- To synchronize the Buildroot git repository:
  `./compile_buildroot.sh -p -n`
- To enter the (ncurses) config menu of Buildroot:
  `./compile_buildroot.sh menuconfig`
- To compile the toolchain:
  `./compile_buildroot.sh toolchain`
- To compile a specific package:
  `./compile_buildroot.sh <package_name>`
- To enter the (ncurses) config menu of Linux kernel:
  `./compile_buildroot.sh linux-menuconfig`
- To show the script help:
  `./compile_buildroot.sh -h`
- To show Buildroot help:
  `./compile_buildroot.sh help`

### Save and load of Buildroot configuration file

When running the script you are prompted to say whether you want to
load/save the configuration file or not.

There are two configuration files. One is the permanent configuration
which is committed in this repository and it is
*raspi_config/buildroot_config*. The second configuration file is the
one used at runtime by Buildroot. This is the file *raspi_build/.config*.
The *compile_buildroot.sh* script copies the first file over the second
before running Buildroot and it does the inverse when exiting Buildroot.

You can avoid doing this by answering *N* when the script asks what to do.
You can also force the script to load/save all the time without asking
by specifying the flag `-y` when calling the script.

### Which Buildroot version to use

There are few variables inside the script you may change to better
represent your needs:

- `BUILDROOT_BASE`: this is the base folder containing all other
  directories (*buildroot*, *raspi4_config* and *raspi4_build*). This
  variable accept a path relative to the script location.
- `BUILDROOT_GIT`: this is the URL of the Buildroot git repository.
- `BUILDROOT_COMMIT`: this is the commit/tag/branch to use from the git
  repository. You can specify *master*, but since it changes when new
  commits are added I suggest to hardcode a specific point in the git
  history instead (a tag or a commit ID).
- `BOARD_NAME`: this is the prefix of the folders *<BOARD_NAME>_config*
  and *<BOARD_NAME>_build*. Default is *raspi4*.
