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

TELEGRAF_NAME="telegraf"
TELEGRAF_TAR="telegraf-1.13.0_linux_armhf.tar.gz"
TELEGRAF_URL="https://dl.influxdata.com/telegraf/releases/$TELEGRAF_TAR"
TELEGRAF_SHA="fceeeba915e462b1559eb1ebe287dfa293e96c33b4c181f6328e9775e6d5ecbc"
TELEGRAF_DL_FILE="$BR2_DL_DIR/$TELEGRAF_TAR"
TELEGRAF_BUILD_DIR="$BUILD_DIR/$TELEGRAF_NAME"

if [ -z "$BUILD_DIR" ] ; then
	echo "This script is intended to be run as post build script in Buildroot environment." >&2
	echo "It depends on some variables set by Buildroot itself." >&2
	echo "Load Buildroot env variables before running this script again." >&2
	exit 1
fi

# Download

echo "Downloading $TELEGRAF_URL..."
if [ ! -f "$TELEGRAF_DL_FILE" ] ; then
	wget -O "$TELEGRAF_DL_FILE" "$TELEGRAF_URL"
	if [ $? != 0 ] ; then
		echo "Fetch of \"$TELEGRAF_URL\" failed!" >&2
		exit 1
	fi
	sha=$(sha256sum $TELEGRAF_DL_FILE | awk '{print $1}')
	if [ $sha != $TELEGRAF_SHA ] ; then
		echo "Hash of the downloaded file doesn't correspond!" >&2
		exit 1
	fi
	echo "Download completed."
else
	echo "File already present, nothing to do."
fi

# Extraction

echo "Extracting $TELEGRAF_DB_FILE in $BUILD_DIR/..."
mkdir -p "$BUILD_DIR"
if [ ! -d "$TELEGRAF_BUILD_DIR" ] ; then
	tar -xf "$TELEGRAF_DL_FILE" -C "$BUILD_DIR"
	if [ $? != 0 ] || [ ! -d "$TELEGRAF_BUILD_DIR" ] ; then
		echo "Failed uncompressing $TELEGRAF_DL_FILE!" >&2
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
		echo "Installation of $TELEGRAF_NAME failed!" >&2
		exit 1
	fi
}

echo "Installing from $TELEGRAF_BUILD_DIR/ to $TARGET_DIR/..."

run_n_check cp -r "$TELEGRAF_BUILD_DIR"/etc "$TARGET_DIR/"
run_n_check cp -r "$TELEGRAF_BUILD_DIR"/usr "$TARGET_DIR/"

# Create additional config file for Raspberry scrape

cat << __EOF__ > "$TARGET_DIR/etc/telegraf/telegraf.d/raspi.conf"
[[inputs.net]]

[[inputs.netstat]]

[[inputs.file]]
  files = ["/sys/class/thermal/thermal_zone0/temp"]
  name_override = "cpu_temperature"
  data_format = "value"
  data_type = "integer"
__EOF__

# Create boot symlink

if [ ! -h "$TARGET_DIR/etc/init.d/S91telegraf" ] ; then
	ln -s "/usr/lib/telegraf/scripts/init.sh" "$TARGET_DIR/etc/init.d/S91telegraf"
	if [ $? != 0 ] ; then
		echo "Creation of boot symlink for $TELEGRAF_NAME failed!" >&2
		exit 1
	fi
fi

# Fix permissions

run_n_check chmod +x "$TARGET_DIR/usr/lib/telegraf/scripts/init.sh"

echo "Installation done."

exit 0
