# Building the OS image

## How to use

![Buildroot](images/buildroot.png)

Buildroot is a fantastic tool all centered on the use of make.
It automates the fetch of all the packages, it downloads as well
the Linux kernel and the toolchain for the cross compilation.
You can learn more about Buildroot by checking the official
website. [Link here](https://buildroot.org/).

The script **"compile_buildroot.sh"** is a wrapper on top of Buildroot.
The features it has are the following:

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
