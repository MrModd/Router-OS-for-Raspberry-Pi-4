#!/bin/bash

##########################################################################
#                                                                        #
#                 *************************************                  #
#                 * Copyright 2019 Federico Cosentino *                  #
#                 *************************************                  #
#                                                                        #
# This program is free software: you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# This program is distributed in the hope that it will be useful,        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with this program.  If not, see <https://www.gnu.org/licenses/>. #
#                                                                        #
##########################################################################

# Source this file when you want to compile buildroot programs
# for the target

if ! [[ "${BASH_SOURCE[0]}" != "${0}" ]] ; then
	echo -e "You should not call this script directy.\nSource it with '. $0'."
	exit 1
fi

# === Edit the following variables if needed ===

BOARD_NAME="raspi4"

# === End of editable variables ===

# Internal variables

CURR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# During execution of Buildroot post-build scripts
# some variables are set with useful paths in
# buildroot installation. Assigning the same variable
# name here for those paths helps making scripts
# working with and without Buildroot.

# These variables are visible during Buildroot
# post-build script execution
export BASE_DIR="$CURR/${BOARD_NAME}_build"
export TARGET_DIR="$BASE_DIR/target"
export HOST_DIR="$BASE_DIR/host"
export BUILD_DIR="$BASE_DIR/build"
export BINARIES_DIR="$BASE_DIR/images"
export BR2_CONFIG="$BASE_DIR/.config"
export BR2_JLEVEL=$(grep -c ^processor /proc/cpuinfo) # Number of CPUs
export BR2_DL_DIR="$BASE_DIR/../buildroot/dl"

# These variables are not visible during Buildroot
# post-build script execution
BR2_TOOLCHAIN_BUILDROOT_VENDOR=$(grep "BR2_TOOLCHAIN_BUILDROOT_VENDOR" "$BR2_CONFIG" | awk -F "=" '{print $2}' | sed "s/\"//g")

# And again a visible variable (depends on toolchain vendor name)
export STAGING_DIR="$HOST_DIR/usr/arm-${BR2_TOOLCHAIN_BUILDROOT_VENDOR}-linux-gnueabihf/sysroot"

echo -n "Setting up environment for Buildroot toolchain"

### Target

# Toolchain

export CROSS_COMPILE="$HOST_DIR/usr/bin/arm-linux-"
export AR="ar"
export AS="as"
export LD="ld"
export NM="nm"
export CC="gcc"
export GCC="gcc"
export CPP="cpp"
export CXX="g++"
export FC="gfortran"
export RANLIB="ranlib"
export READELF="readelf"
export STRIP="strip"
export OBJCOPY="objcopy"
export OBJDUMP="objdump"

export DEFAULT_ASSEMBLER="as"
export DEFAULT_LINKER="ld"

echo -n "."

# Toolchain flags

CXFLAGS="--sysroot=$STAGING_DIR"

echo -n "."

# Additional paths

export OLD_PATH="$PATH"
export PATH="$HOST_DIR/bin:$HOST_DIR/sbin:$HOST_DIR/usr/bin:$HOST_DIR/usr/sbin:$PATH"

echo -n "."

# Make command

export MAKE="$(which make 2> /dev/null)"

# PS1

export OLD_PS1="$PS1"
export PS1="$PS1(target)$ "

echo " OK!"

echo -e "\nUseful exported variables:\n"
echo "BASE_DIR: $BASE_DIR"
echo "TARGET_DIR: $TARGET_DIR"
echo "HOST_DIR: $HOST_DIR"
echo "BUILD_DIR: $BUILD_DIR"
echo "BINARIES_DIR: $BINARIES_DIR"
echo "STAGING_DIR: $STAGING_DIR"
echo "BR2_CONFIG: $BR2_CONFIG"
echo "BR2_JLEVEL: $BR2_JLEVEL"
echo "BR2_DL_DIR: $BR2_DL_DIR"
echo "BR2_TOOLCHAIN_BUILDROOT_VENDOR: $BR2_TOOLCHAIN_BUILDROOT_VENDOR"
echo "STAGING_DIR: $STAGING_DIR"
echo "CROSS_COMPILE: $CROSS_COMPILE"
echo "CXFLAGS: $CXFLAGS"

echo -e "\nAlso these variables are exported:"
echo "AR, AS, LD, NM, CC, GCC, CPP, CXX, FC, RANLIB, READELF, STRIP,"
echo "OBJCOPY, OBJDUMP, DEFAULT_ASSEMBLER, DEFAULT_LINKER, MAKE"

echo -e "\nYou can unset the environment by running \"exit\"."

exit() {
	unset BOARD_NAME
	unset CURR
	unset BASE_DIR
	unset TARGET_DIR
	unset HOST_DIR
	unset BUILD_DIR
	unset BINARIES_DIR
	unset BR2_CONFIG
	unset BR2_JLEVEL
	unset BR2_DL_DIR
	unset BR2_TOOLCHAIN_BUILDROOT_VENDOR
	unset STAGING_DIR
	unset CROSS_COMPILE
	unset AR
	unset AS
	unset LD
	unset NM
	unset CC
	unset GCC
	unset CPP
	unset CXX
	unset FC
	unset RANLIB
	unset READELF
	unset STRIP
	unset OBJCOPY
	unset OBJDUMP
	unset DEFAULT_ASSEMBLER
	unset DEFAULT_LINKER
	unset CXFLAGS
	PATH="$OLD_PATH"
	unset OLD_PATH
	unset MAKE
	PS1="$OLD_PS1"
	unset OLD_PS1
	unset exit

	echo "Bye bye."
	return 0
}

return 0
