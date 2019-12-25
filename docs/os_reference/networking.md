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
