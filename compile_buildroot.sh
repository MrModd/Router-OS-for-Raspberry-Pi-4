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

#############
# Variables #
#############

# === Edit the following variables if needed ===

BUILDROOT_BASE="." # Can be relative to the dir of this script
BUILDROOT_GIT="git://git.buildroot.net/buildroot"
BUILDROOT_COMMIT="e80874cd7f2093ad7aa3912620c44a6641373e6d"
BOARD_NAME="raspi4"

# === End of editable variables ===

# Internal variables

CURR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

# Make BUILDROOT_BASE an absolute path
cd $CURR
BUILDROOT_BASE="$(cd "$BUILDROOT_BASE" && pwd)"

# Script variables
PREPARE="" # -p
NOMAKE="" # -n
DEFYES="" # -y

# Name of this script
SCRIPT_NAME=$0

# Colors
TXT_COLOR="\e[1;34m" # Normal text
CON_COLOR="\e[1;32m" # Confirm messages
ERR_COLOR="\e[1;31m" # Error messages
RST_COLOR="\e[0m"    # Reset terminal color

#############
# Functions #
#############

echo_text() {
	echo -e "$TXT_COLOR$1$RST_COLOR"
}

echo_confirm() {
	echo -e "$CON_COLOR$1$RST_COLOR"
}

echo_error() {
	echo -e "$ERR_COLOR$1$RST_COLOR" >&2
}

clone_buildroot() {
	echo_text "Cloning buildroot repository..."

	if [ ! -d "$BUILDROOT_BASE/buildroot" ] ; then
		git clone $BUILDROOT_GIT $BUILDROOT_BASE/buildroot
		if [ $? != 0 ] ; then
			echo_error "Cannot clone repository."
			exit 1
		fi
		cd $BUILDROOT_BASE/buildroot
	else
		cd $BUILDROOT_BASE/buildroot
		git checkout master && git pull origin master
		if [ $? != 0 ] ; then
			echo_error "Cannot pull repository."
			exit 1
		fi
	fi

	git checkout $BUILDROOT_COMMIT
	if [ $? != 0 ] ; then
		echo_error "Cannot check out to commit $BUILDROOT_COMMIT."
		exit 1
	fi

	echo_confirm "Buildroot repository cloned."
}

__make_recipe() {
	make -C "$BUILDROOT_BASE/buildroot" O="$BUILDROOT_BASE/${BOARD_NAME}_build" "${@}"
	return $?
}

load_files() {
	#Buildroot config file
	if [ -e "$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" ] ; then
		if [ -e "$BUILDROOT_BASE/${BOARD_NAME}_build/.config" ] ; then
			if [ ! $DEFYES ] ; then
				read -p "Load the buildroot config file? [Y|n] " -n 1 -r
				echo # New line
				if [[ ! $REPLY =~ ^[Nn]$ ]] ; then
					echo_text "Load config: starting..."
					__make_recipe BR2_DEFCONFIG="$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" defconfig
					echo_confirm "Load config: done."
				else
					echo_confirm "Load config: skipped."
				fi
			else
				echo_text "Load config: starting..."
				__make_recipe BR2_DEFCONFIG="$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" defconfig
				echo_confirm "Load config: config file loaded."
			fi
		else
			echo_text "Load config: starting..."
			__make_recipe BR2_DEFCONFIG="$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" defconfig
			echo_confirm "Load config: config file loaded."
		fi
	fi
}

store_files() {
	# Buildroot config file
	if [ -e "$BUILDROOT_BASE/${BOARD_NAME}_build/.config" ] ; then
		if [ -e "$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" ] ; then
			if [ ! $DEFYES ] ; then
				read -p "Save the new buildroot config file? [y|N] " -n 1 -r
				echo # New line
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo_text "Save config: starting..."
					__make_recipe BR2_DEFCONFIG="$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" savedefconfig
					echo_confirm "Save config: done."
				else
					echo_confirm "Save config: skipped."
				fi
			else
				echo_text "Save config: starting..."
				__make_recipe BR2_DEFCONFIG="$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" savedefconfig
				echo_confirm "Save config: config file saved."
			fi
		else
			echo_text "Save config: starting..."
			__make_recipe BR2_DEFCONFIG="$BUILDROOT_BASE/${BOARD_NAME}_config/buildroot_config" savedefconfig
			echo_confirm "Save config: config file saved."
		fi
	else
		echo_error "Save config: no config file found!"
	fi
}

make_recipe() {
	# $1+: Arguments to pass to buildroot main makefile
	
	mkdir -p "$BUILDROOT_BASE/${BOARD_NAME}_build"
	mkdir -p "$BUILDROOT_BASE/${BOARD_NAME}_config"

	load_files

	echo_text "Starting Buildroot..."
	__make_recipe "${@}"
	RET=$?
	
	if [ $RET != 0 ] ; then
		echo_error "Make recipe failed!"
		read -p "Do you want to copy config files anyway? [Y|n] " -n 1 -r
		echo # New line
		if [[ ! $REPLY =~ ^[Nn]$ ]] ; then
			store_files
		else
			echo_confirm "Skipped."
		fi
		return $RET
	else
		store_files
	fi

	echo_text "Buildroot ended."
}

print_help() {
cat << EOF >&2
Usage $SCRIPT_NAME [OPTION]... [TARGET [TARGET_OPTION]...]

OPTIONS:
	-h, -?  show this help
	-p      prepare the environment
	-n      don't call make
	-y      Load and save config files without asking

TARGET:
	Refer to Buildroot documentation to see the make receipes.
EOF
}

########
# MAIN #
########

# Parse command line arguments

while getopts "h?pny" opt; do
case "$opt" in
	h|\?)
		print_help
		exit 0
		;;
	p)
		PREPARE="true"
		;;
	n)
		NOMAKE="true"
		;;
	y)
		DEFYES="true"
		;;
esac
done

shift $((OPTIND-1))

# Do stuff

echo_text "Starting..."
if [ ! -d "$BUILDROOT_BASE/buildroot" ] ; then
	echo_text "Buildroot not found, cloning..."
	PREPARE="true"
fi

if [ $PREPARE ] ; then
	clone_buildroot
fi

if [ ! $NOMAKE ] ; then
	make_recipe "$@"
fi

echo_text "Completed."

exit 0
