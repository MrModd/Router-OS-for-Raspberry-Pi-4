# Buildroot OS for Raspberry Pi 4

This repository aims to build a Linux based operating system from scratch using Buildroot.
Main features of this OS are:
- Provide a read only root filesystem with a RW ramfs overlay which makes the board safe to unplug in any moment
- Provide a default configuration which allows to connect to the board via a WiFi network to make further changes (all headless)
- Provide a tool to setup the board as a router between two wireless networks or a wireless network and a wired one.