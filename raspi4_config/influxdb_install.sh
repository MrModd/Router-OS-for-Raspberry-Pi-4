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

# Some variables must be already set:
# - BUILD_DIR
# - HOST_DIR
# - TARGET_DIR
# - STAGING_DIR
# - BR2_JLEVEL
# - BR2_DL_DIR

INFLUXDB_NAME="influxdb-1.7.9-1"
INFLUXDB_TAR="influxdb-1.7.9_linux_armhf.tar.gz"
INFLUXDB_URL="https://dl.influxdata.com/influxdb/releases/$INFLUXDB_TAR"
INFLUXDB_SHA="c3f87938f8349649bf51db0a23683c06515548f6a84a9bcf0068a095e539e99e"
INFLUXDB_DL_FILE="$BR2_DL_DIR/$INFLUXDB_TAR"
INFLUXDB_BUILD_DIR="$BUILD_DIR/$INFLUXDB_NAME"

if [ -z "$BUILD_DIR" ] ; then
	echo "This script is intended to be run as post build script in Buildroot environment." >&2
	echo "It depends on some variables set by Buildroot itself." >&2
	echo "Load Buildroot env variables before running this script again." >&2
	exit 1
fi

# Download

echo "Downloading $INFLUXDB_URL..."
if [ ! -f "$INFLUXDB_DL_FILE" ] ; then
	wget -O "$INFLUXDB_DL_FILE" "$INFLUXDB_URL"
	if [ $? != 0 ] ; then
		echo "Fetch of \"$INFLUXDB_URL\" failed!" >&2
		exit 1
	fi
	sha=$(sha256sum $INFLUXDB_DL_FILE | awk '{print $1}')
	if [ $sha != $INFLUXDB_SHA ] ; then
		echo "Hash of the downloaded file doesn't correspond!" >&2
		exit 1
	fi
	echo "Download completed."
else
	echo "File already present, nothing to do."
fi

# Extraction

echo "Extracting $INFLUXDB_DB_FILE in $BUILD_DIR/..."
mkdir -p "$BUILD_DIR"
if [ ! -d "$INFLUXDB_BUILD_DIR" ] ; then
	tar -xf "$INFLUXDB_DL_FILE" -C "$BUILD_DIR"
	if [ $? != 0 ] || [ ! -d "$INFLUXDB_BUILD_DIR" ] ; then
		echo "Failed uncompressing $INFLUXDB_DL_FILE!" >&2
		exit 1
	fi
	echo "Extraction done."
else
	echo "File already extracted, nothing to do."
fi

# Installation

run_n_check() {
	$*
	if [ $? != 0 ] ; then
		echo "Installation of $INFLUXDB_NAME failed!" >&2
		exit 1
	fi
}

echo "Installing from $INFLUXDB_BUILD_DIR/ to $TARGET_DIR/..."

run_n_check cp -r "$INFLUXDB_BUILD_DIR"/etc "$TARGET_DIR/"
run_n_check cp -r "$INFLUXDB_BUILD_DIR"/usr "$TARGET_DIR/"
run_n_check cp -r "$INFLUXDB_BUILD_DIR"/var/lib "$TARGET_DIR/var/"

# Create boot symlink

if [ ! -h "$TARGET_DIR/etc/init.d/S90influxdb" ] ; then
	ln -s "/usr/lib/influxdb/scripts/init.sh" "$TARGET_DIR/etc/init.d/S90influxdb"
	if [ $? != 0 ] ; then
		echo "Creation of boot symlink for $INFLUXDB_NAME failed!" >&2
		exit 1
	fi
fi

# Fix permissions

run_n_check chmod 777 "$TARGET_DIR/var/lib/influxdb"
run_n_check chmod +x "$TARGET_DIR/usr/lib/influxdb/scripts/init.sh"

echo "Installation done."

exit 0
