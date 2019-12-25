# Troubleshooting

## Compilation error while running add_rpi_custom_config.sh

The script *add_rpi_custom_config.sh* overwrites the file
*raspi4_build/images/rpi-firmware/config.xml*. If the folder is not
there it will fail.

The folder *rpi-firmware/* is generated during the Buildroot compilation
of the package **rpi-firmware**. In case this folder is not present
check if the *rpi-firmware* package is selected in Buildroot under
"Target packages" --> "Hardware handling" --> "Firmware".
If yes try rebuilding the package with the command
`./compile_buildroot.sh rpi-firmware-rebuild`.

## Can't get an IP using the USB-C port of the Raspberry

I think this problem is due to the bad implementation of the USB-C standard.
[Description here](https://www.theverge.com/2019/7/10/20688655/raspberry-pi-4-usb-c-port-bug-e-marked-cables-audio-accessory-charging).

What happens is that you connect your computer via USB to the USB-C port
of the Raspberry to power it up, the Raspberry boots, the computer shows
a new network interface, but there's no way to exchange an ethernet
packet between the two.

You can even set a static ip on the computer, it won't send even a single
ping. And this is because the Raspberry is not receiving any Ethernet
frame. You can verify this by running `sudo tcpdump -i usb0` from the
Raspberry (connect via another network interface or using the UART port).

The only solution I found for now is to unplug and replug the power
cable until it starts working. Try also changing cable or changing
USB port on the computer.

## Slow DHCP exchange on wlan0 makes ifdown and ifup unusable

When starting the wlan0 in managed mode (Raspberry connecting to an
Access Point), if the Raspberry doesn't get an IP from the DCHP server
before the timeout it fails the ifup process for the interface.
This results in wlan0 link down, but wpa_supplicant daemon up.

Normally wpa_supplicant is stopped by `ifdown wlan0`, but since the
link is already down this command doesn't work.

The solution is to kill manually wpa_supplicant with
`sudo killall wpa_supplicant`.

In case this problem persists try increasing the timeout of the DHCP
client. It's the line `udhcpc_opts -t 6` in the file
*/etc/network/interfaces*.

## Grafana displays "Data outside time range"

When the Raspberry is not connected to the internet (as per default
configuration) the internal time starts from the EPOCH time 0:
Jan 1st, 1970. Grafana, instead, takes the date from the device where
you open it from, so the dates don't match. Moreover the EPOCH time 0
is threated by InfluxDB as a null date.

In order to have the correct statistics on Grafana ensure the Raspberry
is connected to the internet. The *ntpd* daemon will take care of
getting the right date.

## influxdb process was unable to start [ FAILED ]

When starting InfluxDB usually shows an error message.

The startup time of InfluxDB is pretty long and the boot script only
waits for 1 second before checking the status. Don't worry about
this error message. If you want to be sure InfluxDB started just wait
at least 20 seconds and then run `sudo /etc/init.d/S90influxdb status`.

# How I solved the problems

## Internal WiFi driver

The internal WiFi kernel driver is a module and it must be loaded by
hand during boot.

The right version of the module to use was found
[here](https://www.raspberrypi.org/forums/viewtopic.php?t=138858).

## USB WiFi driver

The USB Wireless card used is a *TP-LINK TL-WN722N* which uses an
**Atheros AR9271** chipsed. In Buildroot these drivers are under the group
of packages "linux-firmware".

How to load the right modules was discovered by plugging the device on a
computer and looking at the new modules that popped out in lsmod.

## USB-C as Ethernet device

The USB-C port, normally used as power input for the Raspberry, can be used
as another network device. The idea came from this
[YouTube](https://www.youtube.com/watch?v=IR6sDcKo3V8) video.

The modules to load were described
[here](https://www.raspberrypi.org/forums/viewtopic.php?t=249877).

The overlay to use was described
[here](https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget/ethernet-gadget).

## Load modules at boot

The way to load modules during boot process
was suggested by
[this](https://unix.stackexchange.com/questions/396542/buildroot-how-to-load-modules-automatically)
post.

It relies to a couple of scripts taken from the "Linux From Scratch" project.
The files used on this project to load the modules are not my property and
they belong to the persons described at the beginning of the files.

## Long boot time

The SSH daemon was taking minutes to boot. The reason was due to the long
wait to get enough entropy to run ssh-keygen.

The solution is to help the kernel collecting the entropy at boot time using
the package rng-tools.

The solution was suggested
[here](https://unix.stackexchange.com/questions/522271/rpi-buildroot-random-crng-init-done-not-enough-entropy-how-to-configure).

## DHCP server doesn't respond to requests after the first lease

If the DHCP server is not set as authoritative it won't reply to requests
from devices which already had an IP before (and thus they are proposing
to reobtain the same IP). This because after reboot the DHCP server
loses the file with all the leases.

Setting the server as authoritative makes it the only DHCP server in the
network. This makes the server to reply to every DHCP request.

The problem with the solution is described
[here](https://serverfault.com/questions/842528/dnsmasq-not-responding-dhcp-requests-that-dont-follow-a-dhcp-discover).

## Udhcpc negotiation too short

Depending on the kind of network you are trying to connect it may be possible
that the 3 default retries of udhcpc to get an IP from the DHCP are not
sufficient. The connection to the network may be slower than the retries
of the DHCP client.

The solution is to increase the number of retries done by udhcpc by setting
the option in the file /etc/network/interfaces.

This was suggested [here](https://gitlab.alpinelinux.org/alpine/aports/issues/3105).
