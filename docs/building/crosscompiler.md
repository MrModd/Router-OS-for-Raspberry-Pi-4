# Compile using the Buildroot toolchain

The toolchain embedded in Buildroot is used to cross compile all the
binaries and the Linux kernel that will go on the final image of the
OS.

The toolchain, however, can be used also for other compilations. Even
outside Buildroot.

This page explain how to use it.

## Building the toolchain

If you already compiled the OS you will already have the toolchain. It is
under the folder *raspi4_build/host/usr/bin/* and it is prefixed with
*arm-linux-*.

In case you only need to build the toolchain and you don't care about
the OS you can tell Buildroot to only download and compile the toolchain.
You can do it using `compile_buildroot.sh` with the target *toolchain*:

`./compile_buildroot.sh toolchain`

## Staging area

When cross compiling you may want to link your code to some dynamic
libraries which will be present in the target system. The flag `--sysroot`
is to tell gcc to consider the path given as the root filesystem and thus
to link against the dynamic libraries present in $SYSROOT/usr/lib for
example.

In Buildroot the staging area (a.k.a. the sysroot) is in
*raspi4_build/host/usr/arm-buildroot-linux-gnueabihf/sysroot*.

## Preparing the terminal for cross compilation

The script **crosscompile_env.sh** can be used to export some useful
variables. It is a "sourceable" script, meaning you can load it into your
shell with the following command:

`. ./crosscompile_env.sh`

After doing it you will have for example the variable `CROSS_COMPILE`
exported. this is normally used by *make* as prefix to the name of the
compiler. An example rule in a Makefile can be this:

```
%.o: %.c
	$(CROSS_COMPILE)$(CC) $(CFLAGS) -c -o $@ $<
```

Where `$(CC)` normally expands in `gcc` and if making a host-to-host
compilation `$(CROSS_COMPILE)` is an empty string. In case you are
cross compiling, instead, the variable `CROSS_COMPILE` is set to the
prefix of the toolchain binaries.

In the case of Buildroot the toolchain for ARM is prefixed with
*arm-linux-*.

## How to compile

If you have a Makefile, and this is made to support the cross compilation,
calling `make` should be enough to cross compile using the exported
toolchain.

If you want to compile by hand you can use `$CROSS_COMPILE$CC` instead
of `gcc`. Also you'd better specify the flag `--sysroot=$STAGING_DIR`.

So an example is this:

`$CROSS_COMPILE$CC --sysroot=$STAGING_DIR -o test test.c`

## Restore the terminal

In order to unset all the variables exported by the script
*crosscompile_env.sh* execute the command `exit`.
