# Android Privacy Toolkit

Tools for easier maintainance of your privacy

List of tools
-------------

* wifi - easy interface for managing wifi in new Android systems

Wifi.sh
-------

This tool allows you to maintain separate configurations for every wifi
connection and spoof your HW address (MAC) easily.

As of now there are three commands available:
* connect [confname] - allows you to connect to network[s] defined in confname,
where confname is standard wpa_supplicant configuration. This commands inserts
wifi card module to kernel, starts supplicant and DHCP client.
* disconnect - performs cleanup: kills supplicant and dhcp and removes kernel
module
* up [real/fake/MAC] - spoofs/restores HW address, where real restores, fake
uses predefined fake address or allows use custom address
