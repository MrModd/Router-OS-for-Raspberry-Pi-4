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

## Can't connect to Wireless and getting kernel modules WARNING

If you see kernel logs like the one below it's probably that you are
trying to use the wireless card as AP and client at the same time, but
the channel of the two networks don't match.

```
[  159.362960] brcmfmac: brcmf_update_bss_info: wl dtim_assoc failed (-52)
[  159.369682] ------------[ cut here ]------------
[  159.374484] WARNING: CPU: 1 PID: 57 at net/wireless/sme.c:752 __cfg80211_connect_result+0x3a4/0x408 [cfg80211]
[  159.384526] Modules linked in: iptable_nat ipt_MASQUERADE nf_nat_ipv4 nf_nat nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 bridge stp llc ipv6 usb_f_ecm g_ether usb_f_rndis u_ether libcomposite dwcl
[  159.411696] CPU: 1 PID: 57 Comm: kworker/u8:1 Tainted: G        W         4.19.66-v7l #1
[  159.419807] Hardware name: BCM2835
[  159.423331] Workqueue: cfg80211 cfg80211_event_work [cfg80211]
[  159.429204] [<c0212c70>] (unwind_backtrace) from [<c020d2c8>] (show_stack+0x20/0x24)
[  159.436972] [<c020d2c8>] (show_stack) from [<c0981858>] (dump_stack+0xcc/0x110)
[  159.444305] [<c0981858>] (dump_stack) from [<c0222280>] (__warn.part.3+0xcc/0xe8)
[  159.451810] [<c0222280>] (__warn.part.3) from [<c022241c>] (warn_slowpath_null+0x54/0x5c)
[  159.460123] [<c022241c>] (warn_slowpath_null) from [<bf043510>] (__cfg80211_connect_result+0x3a4/0x408 [cfg80211])
[  159.470716] [<bf043510>] (__cfg80211_connect_result [cfg80211]) from [<bf013414>] (cfg80211_process_wdev_events+0x104/0x160 [cfg80211])
[  159.483124] [<bf013414>] (cfg80211_process_wdev_events [cfg80211]) from [<bf0134b8>] (cfg80211_process_rdev_events+0x48/0xa0 [cfg80211])
[  159.495612] [<bf0134b8>] (cfg80211_process_rdev_events [cfg80211]) from [<bf00d2d8>] (cfg80211_event_work+0x24/0x2c [cfg80211])
[  159.507220] [<bf00d2d8>] (cfg80211_event_work [cfg80211]) from [<c023d4b4>] (process_one_work+0x23c/0x518)
[  159.516898] [<c023d4b4>] (process_one_work) from [<c023e578>] (worker_thread+0x60/0x5b8)
[  159.525009] [<c023e578>] (worker_thread) from [<c0243fd4>] (kthread+0x16c/0x174)
[  159.532424] [<c0243fd4>] (kthread) from [<c02010ac>] (ret_from_fork+0x14/0x28)
[  159.539659] Exception stack(0xef30bfb0 to 0xef30bff8)
[  159.544721] bfa0:                                     00000000 00000000 00000000 00000000
[  159.552915] bfc0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
[  159.561107] bfe0: 00000000 00000000 00000000 00000000 00000013 00000000
[  159.567783] ---[ end trace 47050e3fb3cab0dc ]---
```

You are limited in the kind of combinations you can do with one card.
To get a list of allowed combination call `iw list`. For the integrated
WiFi card of the Raspberry Pi 4 B+ this is the list of combinations:

```
valid interface combinations:
         * #{ managed } <= 1, #{ P2P-device } <= 1, #{ P2P-client, P2P-GO } <= 1,
           total <= 3, #channels <= 2
         * #{ managed } <= 1, #{ AP } <= 1, #{ P2P-client } <= 1, #{ P2P-device } <= 1,
           total <= 4, #channels <= 1
```

The second combination tells you can use the card as client (managed)
and as access point (AP) at the same time as long as the two networks
are configured on the same wireless channel/frequency (channels <= 1).

So, when configuring *hostapd.conf* be sure the channel equals the one
of the wireless configured in *wpa_supplicant.conf*.

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
