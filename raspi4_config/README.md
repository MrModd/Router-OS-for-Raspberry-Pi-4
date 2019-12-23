# Content of the raspi4_config folder

There are some changes and fixes that are done after Buildroot has finished
compiling and assembling the filesystem.

This folder contains some files that are copied in the final filesystem as
well as some scripts used to make some fixes before the filesystem is packed
in an .img file.

## Description of the content

- buildroot_config: this is the configuration of Buildroot. This is loaded
  to the buildroot/ folder before running make on Buildroot.
- overlay/: this folder contains the files copied in the root filesystem
  before packing everything in the .img file. This folder is merged with
  the root filesystem folder, so the files in it must respect the same
  folder structure of the root filesystem.
- device_table.txt: this file contains the description of the files and
  folders permissions inside overlay/. A chmod to the parameters described
  here is applied when mergin overlay/ with the root filesystem.
- add_rpi_custom_config.sh: this script overwrite the file
  raspi4_build/images/rpi-firmware/config.xml.
  This is the configuration file used by the Raspberry CPU to configure the
  hardware before loading the Linux kernel. The folder rpi-firmware/ is
  generated during the Buildroot compilation of the package rpi-firmware.
  In case this folder is not present check if the rpi-firmware package
  is selected in Buildroot under "Target packages" --> "Hardware handling"
  --> "Firmware". If yes try rebuilding the package with the command
  `./compile_buildroot.sh rpi-firmware-rebuild`.
- user_table.txt: this file describes the users to be created in the
  system.

# Change the network configuration

The network configuration is stored in few files.
Changing those files is sufficient to reconfigure all the interfaces and
the network daemons.

Here is the list:

- /etc/dnsmasq.conf
- /etc/hostapd.conf
- /etc/wpa_supplicant.conf
- /etc/net_bridges.txt
- /etc/wlan_virtdev.txt
- /etc/network/interfaces
- /etc/firewall.d/config
- /etc/firewall.d/firewall_rules.txt
- /etc/firewall.d/ports_forwarding.txt

You can print the entire configuration of the board by calling the command
`show_config`.

## dnsmasq.conf

This is the configuration file of Dnsmasq.
This tool includes several servers. We use it mostly for its DHCP server
and its DNS server.

The syntax of the configuration file can be found online. A good explanation
is given in the [Arch Wiki page](https://wiki.archlinux.org/index.php/Dnsmasq).

## hostapd.conf

This is the configuration file of the daemon Hostapd.
Its purpose is to setup the wireless interface in AP mode.

The configuration of Hostapd can be very complex. As usual the Arch Wiki
is one of the best sources of information, so
[here is the page](https://wiki.archlinux.org/index.php/software_access_point).

In the page is also described how to use the same wireless device for
both sharing the connection and connecting to another AP. You can set
the virtual device using the config file */etc/wlan_virtdev.txt* (described
below). Note that using only one WiFi adapter for managed and AP modes at
the same time **is not recommended** and the resulting network may be very
slow.

You can also find some sample configurations
[here](https://wiki.gentoo.org/wiki/Hostapd).

## wpa_supplicant.conf

WPA Supplicant is a tool used to set up the link layer of a WiFi network.
Which means to connect to an access point and authenticate if required.

The config file can be very simple. The mandatory fields are only the name
of the network (ssid) and the key (psk if any or key_mgmt=NONE if none).

Some examples are given in the sample file which is installed in the
OS image. The psk field can either contain the plain text passphrase of
the network or an encoded version of it. You can use the `wpa_passphrase`
tool to generate it.

## net_bridges.txt

This config file contains the list of bridges to set up at boot time.
Each line is a different bridge and it's made of several columns
divided by one or more spaces.

The first column is the name of the bridge to create. This must be unique
in the system, else the creation will fail.

The following columns are all the interfaces to include in the bridge.

`# <Bridge name> <Interface1> <Interface2> ...`

Note that the interfaces are also brought up when the bridge is built
and brought down when the bridge is destroyed.

## wlan_virtdev.txt

This is to add virtual interfaces to wireless network cards. This is useful
if you want to connect one WiFi device to a network while creating an AP
at the same time (as explained in the hostapd.conf section).

The syntax is the same as *net_bridge.txt*.
The first column is the name of the physical interface where you want to
create the new virtual interface. The second column is the name you want
to give to the new virtual interface. The third column is the kind of
interface you are declaring.
Refer to the documentation of `iw` to find the types you can use.

`# <Physical device> <Virtual device> <Type>`

## network/interfaces

The *interfaces* file is used by ifupdown to bring up and down the network
devices. This is widely used in many GNU/Linux distributions including
Debian and all the derivates.

A good explanation on how to set it can be found in the
[Debian Wiki](https://wiki.debian.org/NetworkConfiguration), first section.

## firewall.d

The *firewall.d* folder contains the configuration for the script responsible
of setting up iptables.

### firewall.d/config

This is the global configuration of the firewall. It's made of three sections.
A global section, one section related to the NAT setup and one dedicated to
the filtering of the packets.

The global section contains only one variable: *GlobalEnable*. If set to false
it will skip the entire setup of iptables. If set to true the other two sections
are evaluated.

The NAT section has an enabler variable (*EnableNat*) and some other variables
which identify the topology of the network (which interface is connected to the
world, which one to the NATted network and other info).

The Firewall section has as well an enabler (*EnableFirewall*) and one variable
to decide wheter to allow or reject ping requests.

### firewall.d/firewall_rules.txt

If the Firewal is enabled all the incoming traffic is dropped by default (except
for SSH traffic). This file is used to add exceptions and thus to allow incoming
traffic to some specific ports.

It's a list of rules. One rule per line with the fields divided by one or more
spaces.

This is the list of columns:

`# <Protocol> <Interface (internal/external/all)> <Port>`

Protocol can be either `tcp` or `udp`. The second column applies when the NAT is
enabled: it identifies if the rule has to be applied on the world facing interface,
to the internal network or both. If the NAT is disable you should always put `all`
here. The third column is the port you want to open.

### firewall.d/ports_forwarding.txt

When the NAT is enabled this file contains the rules to forward external traffic
to a specific address in the local network.

This is the syntax:

`# <Protocol (tcp/udp)> <External port> <Internal IP> <Internal port>`

Protocol is either `tcp` or `udp`, external port is the port to open
on the world facing interface which is then translated into the
internal port number and forwarded to the internal IP host.

# Web dashboard for internal monitoring

This Linux distribution comes with a Web UI that displays info about
the Raspberry itself.

The monitoring platform is made of 3 components. The time series
database ((InfluxDB)[https://www.influxdata.com/products/influxdb-overview/])
which stores the metrics, the metrics collector
((Telegraf)[https://www.influxdata.com/time-series-platform/telegraf/])
which periodically gets the value from the system and pushes them in the DB,
and finally the Web UI ((Grafana)[https://grafana.com/grafana/]).

Grafana is a powerful tool you can use to display data coming from a
various number of different sources.
Anyone can prepare a dashboard and share it on the official portal
(link here)[https://grafana.com/grafana/dashboards]). For this project
the best choice was the
(Raspberry Pi Monitoring)[https://grafana.com/grafana/dashboards/10578].
With some small modifications on what Telegraf has to collect from the
system this premade dashboard shows all the needful information for
the monitoring of the Raspberry.

You can access the dashboard by connecting to the IP of the Raspberry
and port 3000. So default is: <http://192.168.1.1:3000/>.

Use "admin" as user and password. You'll be prompt to change it at the
first access.

# Troubleshooting

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
Jan 1st 1970. Grafana, instead, takes the date from the device where
you open it from, so the dates don't match. Moreover the EPOCH time 0
is threated by InfluxDB as a null date.

In order to have the correct statistics on Grafana ensure the Raspberry
is connected to the internet. The *ntpd* daemon will take care of
getting the right date.

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
