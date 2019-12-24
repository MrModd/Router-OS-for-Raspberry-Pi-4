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

GRAFANA_NAME="grafana-6.5.2"
GRAFANA_TAR="grafana-6.5.2.linux-armv7.tar.gz"
GRAFANA_URL="https://dl.grafana.com/oss/release/$GRAFANA_TAR"
GRAFANA_SHA="c34ee5332d161ef20a63b1d281f782870bc96d85bfe97d0a7802da7f7cd6a6ec"
GRAFANA_DL_FILE="$BR2_DL_DIR/$GRAFANA_TAR"
GRAFANA_BUILD_DIR="$BUILD_DIR/$GRAFANA_NAME"
# The dashboard is taken from the Grafana Lab portal.
# It is optimized for the Raspberry metrics and sensors.
# Link here: https://grafana.com/grafana/dashboards/10578
DASHBOARD_URL="https://grafana.com/api/dashboards/10578/revisions/1/download"
DASHBOARD_JSON_DST="$TARGET_DIR/usr/share/grafana/conf/dashboards/raspberry.json"

if [ -z "$BUILD_DIR" ] ; then
	echo "This script is intended to be run as post build script in Buildroot environment." >&2
	echo "It depends on some variables set by Buildroot itself." >&2
	echo "Load Buildroot env variables before running this script again." >&2
	exit 1
fi

# Download

echo "Downloading $GRAFANA_URL..."
if [ ! -f "$GRAFANA_DL_FILE" ] ; then
	wget -O "$GRAFANA_DL_FILE" "$GRAFANA_URL"
	if [ $? != 0 ] ; then
		echo "Fetch of \"$GRAFANA_URL\" failed!" >&2
		exit 1
	fi
	sha=$(sha256sum $GRAFANA_DL_FILE | awk '{print $1}')
	if [ $sha != $GRAFANA_SHA ] ; then
		echo "Hash of the downloaded file doesn't correspond!" >&2
		exit 1
	fi
	echo "Download completed."
else
	echo "File already present, nothing to do."
fi

# Extraction

echo "Extracting $GRAFANA_DB_FILE in $BUILD_DIR/..."
mkdir -p "$BUILD_DIR"
if [ ! -d "$GRAFANA_BUILD_DIR" ] ; then
	tar -xf "$GRAFANA_DL_FILE" -C "$BUILD_DIR"
	if [ $? != 0 ] || [ ! -d "$GRAFANA_BUILD_DIR" ] ; then
		echo "Failed uncompressing $GRAFANA_DL_FILE!" >&2
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
		echo "Installation of $GRAFANA_NAME failed!" >&2
		exit 1
	fi
}

echo "Installing from $GRAFANA_BUILD_DIR/ to $TARGET_DIR/..."

run_n_check mkdir -p "$TARGET_DIR/usr/bin/"
run_n_check cp "$GRAFANA_BUILD_DIR/bin/grafana-cli" "$TARGET_DIR/usr/bin/grafana-cli"
run_n_check cp "$GRAFANA_BUILD_DIR/bin/grafana-server" "$TARGET_DIR/usr/bin/grafana-server"
run_n_check mkdir -p "$TARGET_DIR/usr/share/grafana"
run_n_check cp -r "$GRAFANA_BUILD_DIR/conf" "$TARGET_DIR/usr/share/grafana/"
run_n_check cp -r "$GRAFANA_BUILD_DIR/public" "$TARGET_DIR/usr/share/grafana/"
run_n_check cp -r "$GRAFANA_BUILD_DIR/scripts" "$TARGET_DIR/usr/share/grafana/"
run_n_check cp -r "$GRAFANA_BUILD_DIR/tools" "$TARGET_DIR/usr/share/grafana/"
run_n_check mkdir -p "$TARGET_DIR/usr/share/grafana/data/" # Folder used to store the current config and data
run_n_check chmod 777 "$TARGET_DIR/usr/share/grafana/data"

# Creating the provisioning files
# For info about the provisioning: https://grafana.com/docs/grafana/latest/administration/provisioning/

cat << __EOF__ > "$TARGET_DIR/usr/share/grafana/conf/provisioning/datasources/influxdb.yaml"
apiVersion: 1

datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    isDefault: true
    database: telegraf
    url: http://localhost:8086
    editable: true
    jsonData:
      httpMode: GET
__EOF__

cat << __EOF__ > "$TARGET_DIR/usr/share/grafana/conf/provisioning/dashboards/raspberry.yaml"
apiVersion: 1

providers:
 - name: 'Raspberry'
   orgId: 1
   folder: ''
   folderUid: ''
   type: file
   disableDeletion: false
   editable: true
   updateIntervalSeconds: 10
   allowUiUpdates: true
   options:
     path: /usr/share/grafana/conf/dashboards
__EOF__

# Download the premade dashboard

run_n_check mkdir -p "$TARGET_DIR/usr/share/grafana/conf/dashboards"
run_n_check wget -O - "$DASHBOARD_URL" | sed "2,11d" | sed 's/${DS_INFLUXDB}/InfluxDB/g' > "$DASHBOARD_JSON_DST"

# Create boot script

cat << __EOF__ > "$TARGET_DIR/etc/init.d/S93grafana"
#!/bin/bash

# init script adapted from the InfluxDB init.sh script

# Daemon options
GRAFANA_OPTS=

# Process name ( For display )
NAME=grafana-server

# User and group
USER=grafana
GROUP=grafana

# Check for sudo or root privileges before continuing
if [ "\$UID" != "0" ]; then
    echo "You must be root to run this script"
    exit 1
fi

# Daemon name, where is the actual executable If the daemon is not
# there, then exit.
DAEMON=/usr/bin/grafana-server
if [ ! -x \$DAEMON ]; then
    echo "Executable \$DAEMON does not exist!"
    exit 5
fi

# Home folder of Grafana installation
HOMEPATH=/usr/share/grafana

# PID file for the daemon
PIDFILE=/var/run/grafana/grafana.pid
PIDDIR=\$(dirname \$PIDFILE)
if [ ! -d "\$PIDDIR" ]; then
    mkdir -p \$PIDDIR
    chown \$USER:\$GROUP \$PIDDIR
fi

# Logging
if [ -z "\$STDOUT" ]; then
    STDOUT=/dev/null
fi

if [ ! -f "\$STDOUT" ]; then
    mkdir -p \$(dirname \$STDOUT)
fi

if [ -z "\$STDERR" ]; then
    STDERR=/var/log/grafana/grafana.log
fi

if [ ! -f "\$STDERR" ]; then
    mkdir -p \$(dirname \$STDERR)
fi

function log_failure_msg() {
    echo "\$@" "[ FAILED ]"
}

function log_success_msg() {
    echo "\$@" "[ OK ]"
}

function start() {
    # Check that the PID file exists, and check the actual status of process
    if [ -f \$PIDFILE ]; then
        PID="\$(cat \$PIDFILE)"
        if kill -0 "\$PID" &>/dev/null; then
            # Process is already up
            log_success_msg "\$NAME process is already running"
            return 0
        fi
    else
        su -s /bin/sh -c "touch \$PIDFILE" \$USER &>/dev/null
        if [ \$? -ne 0 ]; then
            log_failure_msg "\$PIDFILE not writable, check permissions"
            exit 5
        fi
    fi

    # Launch process
    echo "Starting \$NAME..."
    if command -v start-stop-daemon &>/dev/null; then
        start-stop-daemon \
            --chuid \$USER:\$GROUP \
            --start \
            --quiet \
            --pidfile \$PIDFILE \
            --exec \$DAEMON \
            -- \
            -pidfile \$PIDFILE \
            -homepath \$HOMEPATH \
            \$GRAFANA_OPTS >>\$STDOUT 2>>\$STDERR &
    else
        local CMD="\$DAEMON -pidfile \$PIDFILE -homepath \$HOMEPATH \$GRAFANA_OPTS >>\$STDOUT 2>>\$STDERR &"
        su -s /bin/sh -c "\$CMD" \$USER
    fi

    # Sleep to verify process is still up
    sleep 1
    if [ -f \$PIDFILE ]; then
        # PIDFILE exists
        if kill -0 \$(cat \$PIDFILE) &>/dev/null; then
            # PID up, service running
            log_success_msg "\$NAME process was started"
            return 0
        fi
    fi
    log_failure_msg "\$NAME process was unable to start or it's still loading"
    exit 1
}

function stop() {
    # Stop the daemon.
    if [ -f \$PIDFILE ]; then
        local PID="\$(cat \$PIDFILE)"
        if kill -0 \$PID &>/dev/null; then
            echo "Stopping \$NAME..."
            # Process still up, send SIGTERM and remove PIDFILE
            kill -s TERM \$PID &>/dev/null && rm -f "\$PIDFILE" &>/dev/null
            n=0
            while true; do
                # Enter loop to ensure process is stopped
                kill -0 \$PID &>/dev/null
                if [ "\$?" != "0" ]; then
                    # Process stopped, break from loop
                    log_success_msg "\$NAME process was stopped"
                    return 0
                fi

                # Process still up after signal, sleep and wait
                sleep 1
                n=\$(expr \$n + 1)
                if [ \$n -eq 30 ]; then
                    # After 30 seconds, send SIGKILL
                    echo "Timeout exceeded, sending SIGKILL..."
                    kill -s KILL \$PID &>/dev/null
                elif [ \$? -eq 40 ]; then
                    # After 40 seconds, error out
                    log_failure_msg "could not stop \$NAME process"
                    exit 1
                fi
            done
        fi
    fi
    log_success_msg "\$NAME process already stopped"
}

function restart() {
    # Restart the daemon.
    stop
    start
}

function status() {
    # Check the status of the process.
    if [ -f \$PIDFILE ]; then
        PID="\$(cat \$PIDFILE)"
        if kill -0 \$PID &>/dev/null; then
            log_success_msg "\$NAME process is running"
            exit 0
        fi
    fi
    log_failure_msg "\$NAME process is not running"
    exit 1
}

case \$1 in
    start)
        start
        ;;

    stop)
        stop
        ;;

    restart)
        restart
        ;;

    status)
        status
        ;;

    version)
        \$DAEMON -v
        ;;

    *)
        # For invalid arguments, print the usage message.
        echo "Usage: \$0 {start|stop|restart|status|version}"
        exit 2
        ;;
esac
__EOF__

run_n_check chmod +x "$TARGET_DIR/etc/init.d/S93grafana"

echo "Installation done."

exit 0
