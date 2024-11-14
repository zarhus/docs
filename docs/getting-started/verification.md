# Verification

This document describes image verification for Embedded Linux newbies, so, if
you are new or think that some Linux and Yocto concepts passed you by - feel
free to proceed with reading this guide, you will find essentials here!

Every Linux image should provide a list of basic functionalities, including,
apart from booting, a list of basic packages (in case of Zarhus it is defined by
Yocto Project) and a list of working basic interfaces.

!!! note

    Though the following chapters present "basic interfaces" which Zarhus OS
    provides support for, some of the interfaces may not be available for your
    target, if so, check [your target page](../supported-targets/targets.md).

## Prerequisites

There is no image verification without an image, right? So, proceed with
[building](./building.md) and [flashing](./flashing.md) steps firstly.

Hardware prerequisites:

* Power supply for your target, refer to [your target
  page](../supported-targets/targets.md) for more information;
* Serial communication devices, refer to [your target
  page](../supported-targets/targets.md) and check how to establish serial
  communication with your target;
* A cable for Ethernet connection with your target.

## Verification

The verification is an execution of a set of basic commands on the running
system to prove the functionality of Zarhus OS.

### Booting platform

This is the basic functionality of all OSes. To verify this, you need to connect
to the serial port of your target and start communication with your host device,
check [your target page](../supported-targets/targets.md) on how to do so.

Plug in target power supply after the connection has been established and check
for following logs:

```bash
(...)

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x412fd050]
[    0.000000] Linux version 6.6.23-yocto-standard-00118-g2d01bc1d4eea (oe-user@oe-host) (aarch64-zarhus-linux-gcc (G4
[    0.000000] KASLR disabled due to lack of seed
[    0.000000] Machine model: Radxa Compute Module 3(CM3) IO Board
[    0.000000] efi: UEFI not found.
[    0.000000] earlycon: uart0 at MMIO32 0x00000000fe660000 (options '1500000n8')
[    0.000000] printk: bootconsole [uart0] enabled
[    0.000000] NUMA: No NUMA configuration found
[    0.000000] NUMA: Faking a node at [mem 0x0000000000200000-0x00000000efffffff]
[    0.000000] NUMA: NODE_DATA [mem 0xef8239c0-0xef825fff]
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000000200000-0x00000000efffffff]
[    0.000000]   DMA32    empty
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000200000-0x00000000efffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000000200000-0x00000000efffffff]
[    0.000000] On node 0, zone DMA: 512 pages in unavailable ranges
[    0.000000] cma: Reserved 32 MiB at 0x00000000ed800000 on node -1
[    0.000000] psci: probing for conduit method from DT.
[    0.000000] psci: PSCIv1.1 detected in firmware.
[    0.000000] psci: Using standard PSCI v0.2 function IDs


(...)
[    0.950871] systemd[1]: systemd 255.4^ running in system mode (-PAM -AUDIT -SELINUX -APPARMOR +IMA -SMACK +SECCOMP)
[    0.953829] systemd[1]: Detected architecture arm64.

Welcome to Distro for Zarhus product 0.1.0 (scarthgap)!

(...)
[  OK  ] Reached target Bluetooth Support.
[  OK  ] Reached target Multi-User System.
         Starting Record Runlevel Change in UTMP...
[  OK  ] Finished Record Runlevel Change in UTMP.
[  OK  ] Finished Virtual Console Setup.

Distro for Zarhus product 0.1.0 radxa-cm3 ttyS2

radxa-cm3 login:
```

!!! note
    Above logs are for Zarhus OS port for a Radxa board, but you should see
    similar logs, because these are considered to be the common Linux boot logs.

### Basic packages

[There](https://git.yoctoproject.org/poky/tree/meta/recipes-extended/packagegroups/packagegroup-core-base-utils.bb?id=86ae0ef3da48790bd91763fccf32d11894c5b1f4)
is a list with basic packages included into all Zarhus OS images for all
platforms. Below are some examples how to verify version of these utilities
after you have booted into Zarhus OS:

```bash
# tar --version
tar (GNU tar) 1.34
Copyright (C) 2021 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by John Gilmore and Jay Fenlason.

# time --version
time (GNU Time) UNKNOWN
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by David Keppel, David MacKenzie, and Assaf Gordon.

# chronyc -v
chronyc (chrony) version 4.1 (+READLINE -SECHASH +IPV6 -DEBUG)
```

### Basic operation of common interfaces

#### USB

Type `lsblk` command before and after plugging SSD/USB disk via USB port. You
should see a new device (`sda` in this case) appears in the system:

```bash
(before plugging in)
# lsblk
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
mmcblk2      179:0    0   7.1G  0 disk
|-mmcblk2p1  179:1    0    64M  0 part
`-mmcblk2p2  179:2    0     6G  0 part /
mmcblk2boot0 179:8    0    16M  1 disk
mmcblk2boot1 179:16   0    16M  1 disk
(after plugging in)
# lsblk
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda            8:0    0 223.6G  0 disk
`-sda1         8:1    0 223.6G  0 part
mmcblk2      179:0    0   7.1G  0 disk
|-mmcblk2p1  179:1    0    64M  0 part
`-mmcblk2p2  179:2    0     6G  0 part /
mmcblk2boot0 179:8    0    16M  1 disk
mmcblk2boot1 179:16   0    16M  1 disk
```

If it can be mounted (the partition on the device should have file system so to
be able to be mounted), that means that the USB interface works properly:

```bash
# mkdir /mnt/storage
# mount /dev/sda1 /mnt/storage
# lsblk
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda            8:0    0 223.6G  0 disk
`-sda1         8:1    0 223.6G  0 part /mnt/storage
mmcblk2      179:0    0   7.1G  0 disk
|-mmcblk2p1  179:1    0    64M  0 part
`-mmcblk2p2  179:2    0     6G  0 part /
mmcblk2boot0 179:8    0    16M  1 disk
mmcblk2boot1 179:16   0    16M  1 disk
```

#### Ethernet

After connecting the Ethernet cable to the RJ-45 port on a target platform,
you should automatically gain access to the network, meaning that the device
should get an IP address. Depending on your target platform, the IP address will
vary because of the DHCP gateway.

Here is a way you can check your device IP address on Zarhus OS:

```bash
# ifconfig eth0
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.66  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 2a02:a312:c640:680:55b6:53d7:ff91:b44c  prefixlen 64  scopeid 0x0<global>
        inet6 fe80::6210:d748:417c:1e29  prefixlen 64  scopeid 0x20<link>
        ether 00:d0:12:ab:f6:4a  txqueuelen 1000  (Ethernet)
        RX packets 176  bytes 20962 (20.4 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 100  bytes 11279 (11.0 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

In above logs field `inet` is followed by the device IPv4 address which, in this
case, is `192.168.0.66`.

If internet connection is available in your infrastructure, the device should be
able to reach the external addresses, e.g.:

```bash
# ping 8.8.8.8 -c 5
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: icmp_seq=0 ttl=109 time=24.108 ms
64 bytes from 8.8.8.8: icmp_seq=1 ttl=109 time=21.746 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=109 time=21.540 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=109 time=18.388 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=109 time=17.507 ms
--- 8.8.8.8 ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max/stddev = 17.507/20.658/24.108/2.406 ms
```
