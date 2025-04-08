# Zarhus OS on CROSSCON Hypervisor on RPi 4

This guide provides info on how to boot Zarhus OS on a Raspberry Pi 4 device
running the
[CROSSCON Hypervisor](https://github.com/crosscon/CROSSCON-Hypervisor).

## Build CROSSCON Hypervisor

First, follow the
[default demo](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/67eb25c97dda2457ca08fa1a10ea68c9c6095b05/rpi4-ws/README.md)
using the
[docker environment](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/b437f7ecfe2a24bed6219e805ad0133882b832f4/env/README.md)
to isolate the dependencies.
Make sure to save the content of the prepared boot partition, so that
it will not be lost, as it will be needed later.

## Build Zarhus

Zarhus OS will also have to be built (on the host).
Make sure to run this exact build command:

```bash
SHELL=/bin/bash KAS_MACHINE=raspberrypi4-64 kas-container build meta-zarhus/kas/common.yml:meta-zarhus/kas/cache.yml:meta-zarhus/kas/debug.yml:meta-zarhus/kas/rpi.yml
```

!!! note

    The `KAS_MACHINE` variable is significant, `raspberrypi4` would build a
    32-bit version of the system - `raspberrypi4-64` needs to be used in order
    to get a 64-bit version, so that it's compatible with the hypervisor.

## Replacing kernel

When the Zarhus OS build finishes, flash the SD card:

```bash
cd build/tmp/deploy/images/raspberrypi4-64/
sudo bmaptool copy --bmap zarhus-base-image-debug-raspberrypi4-64.rootfs.wic.bmap zarhus-base-image-debug-raspberrypi4-64.rootfs.wic.gz /dev/sd[X]
```

!!! note
    Replace `/dev/sd[X]` with the actual card.

Once that finishes, remount the card and delete everything from the `/boot`
partition, replacing it with the content produced by the CROSSCON Hypervisor
demo step above.

The kernel from the CROSSCON demo also needs to be swapped with the Zarhus OS
kernel. It can be done by first copying the new kernel to the container (make
sure to copy the actual kernel, not the symlink):

```bash
cd build/tmp/deploy/images/raspberrypi4-64/
docker cp -L Image crosscon_hv_container:/work/Image
```

!!! note

    `-L` argument is needed to copy underlying file instead of symlink

## The final image

The Hypervisor will have to be recompiled, starting from
[step 9](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/67eb25c97dda2457ca08fa1a10ea68c9c6095b05/rpi4-ws/README.md#step-9-bind-linux-image-and-device-tree)
of the original demo.

First apply this change to the device tree file in `rpi4-ws` folder (make
sure this is done inside the container):

```patch
root@565810a48049:/work/crosscon/rpi4-ws# git --no-pager diff rpi4.dts
diff --git a/rpi4-ws/rpi4.dts b/rpi4-ws/rpi4.dts
index 0a690a0..3d06bbc 100644
--- a/rpi4-ws/rpi4.dts
+++ b/rpi4-ws/rpi4.dts
@@ -18,7 +18,7 @@

     chosen {
         stdout-path = "serial1:115200n8";
-        bootargs = "earlycon clk_ignore_unused ip=192.168.42.15 carrier_timeout=0";
+        bootargs = "8250.nr_uarts=8 root=/dev/mmcblk1p2 rw rootwait console=ttyS1,115200 earlycon clk_ignore_unused ip=192.168.42.15 carrier_timeout=0";
     };

     reserved-memory {
@@ -824,7 +824,7 @@
             pinctrl-names = "default";
             pinctrl-0 = <0x07 0x08>;
             uart-has-rtscts;
-            status = "okay";
+            status = "disabled";

             bluetooth {
                 compatible = "brcm,bcm43438-bt";
@@ -1402,14 +1402,14 @@
         #address-cells = <0x02>;
         #size-cells = <0x01>;
         ranges = <0x00 0x7e000000 0x00 0xfe000000 0x1800000>;
-        dma-ranges = <0x00 0xc0000000 0x00 0x00 0x40000000>;
+        dma-ranges = <0x0 0x0 0x0 0x0 0xfc000000>;

         emmc2@7e340000 {
             compatible = "brcm,bcm2711-emmc2";
             reg = <0x00 0x7e340000 0x100>;
             interrupts = <0x00 0x7e 0x04>;
             clocks = <0x06 0x33>;
-            status = "disabled";
+            status = "okay";
             vqmmc-supply = <0x1e>;
             vmmc-supply = <0x1f>;
             broken-cd;
root@565810a48049:/work/crosscon/rpi4-ws#
```

!!! note

    This `git diff` was put here in order to outline the changes that
    need to be made to the `rpi4.dts` file. It can work as a patch to be
    applied, but if it doesn't apply, installing some sort of text editor
    on the container in order to apply the changes manually will be necessary:
    ```bash
    apt-get update
    apt-get upgrade
    apt-get install vim nano
    ```

The reasoning for these changes is as follows:

* `8250.nr_uarts=8` tells the `8250` serial driver to allocate up to 8 serial
ports. This is necessary, because if this line is not here, logs from OS level
will not show up on the console.
* `root=/dev/mmcblk1p2` tells the kernel that there is a `/root` partition
at that location. By default, the CROSSCON Hypervisor doesn't have a `rootfs`
or a partition for it, so this has to be added.
* `rw` ensures that the `rootfs` gets mounted in `read-write` mode, rather
than `read-only`.
* `rootwait` tells the kernel to wait until the root device (in this case,
`/dev/mmcblk1p2`) is detected and available before trying to mount it. There
can be a delay when enumerating the storage device, so this stops the kernel
from giving up too early.
* `console=ttyS1,115200` sets the right console, this enables access to the
console and logs from OS level.
* setting `status = "disabled"` for the Bluetooth driver, while technically not
necessary, is a good practice as it can disrupt the serial console setup.
* Finally, setting the `dma-ranges` and `status="okay"` for the `emmc2bus`
enables the whole SD card storage device.

Then run the following commands:

```bash
root@565810a48049:/# cd /work/crosscon
root@565810a48049:/work/crosscon# dtc -I dts -O dtb rpi4-ws/rpi4.dts > rpi4-ws/rpi4.dtb
root@565810a48049:/work/crosscon# cd lloader
root@565810a48049:/work/crosscon/lloader# rm linux-rpi4.bin
root@565810a48049:/work/crosscon/lloader# rm linux-rpi4.elf
root@565810a48049:/work/crosscon/lloader# make  \
    IMAGE=/work/Image \
    DTB=../rpi4-ws/rpi4.dtb \
    TARGET=linux-rpi4.bin \
    CROSS_COMPILE=aarch64-none-elf- \
    ARCH=aarch64
```

Notice that this step has changed, so instead of using the kernel
from `linux/build-aarch64/arch/arm64/boot/`, the kernel from
the Yocto deploy directory is used.

Now the CROSSCON Hypervisor is almost ready to be built - just one more change
needs to be applied:

```git
root@565810a48049:/work/crosscon/CROSSCON-Hypervisor# git diff src/arch/armv8/aborts.c
diff --git a/src/arch/armv8/aborts.c b/src/arch/armv8/aborts.c
index a7f5adc..90e1262 100644
--- a/src/arch/armv8/aborts.c
+++ b/src/arch/armv8/aborts.c
@@ -43,6 +43,7 @@ void internal_abort_handler(uint64_t gprs[]) {

 void aborts_data_lower(uint64_t iss, uint64_t far, uint64_t il)
 {
+    printk("\x9D");
     if (!(iss & ESR_ISS_DA_ISV_BIT) || (iss & ESR_ISS_DA_FnV_BIT)) {
         ERROR("no information to handle data abort (0x%x)", far);
     }
root@565810a48049:/work/crosscon/CROSSCON-Hypervisor#
```

!!! note

    Again, just like in the above `git diff`, a text editor might be
    necessary to use in order to apply this change.

This additional `printk` keeps the UART output going, so that the console can
be accessed. `\x9D` is unprintable character and is used so it doesn't pollute
serial output. It mostly works (sometimes you can see cursor changing position).
Right now, according to
[this issue](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/issues/8#issuecomment-2702293550)
this is the only workaround.

Now the commands needed to build the Hypervisor can be re-ran:

```bash
root@565810a48049:/# CONFIG_REPO=/work/crosscon/rpi4-ws/configs
root@565810a48049:/# cd /work/crosscon

root@565810a48049:/work/crosscon# make -C CROSSCON-Hypervisor/ \
	PLATFORM=rpi4 \
	CONFIG_BUILTIN=y \
	CONFIG_REPO=$CONFIG_REPO \
	CONFIG=rpi4-single-vTEE \
	OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
	CROSS_COMPILE=aarch64-none-elf- \
        clean

root@565810a48049:/work/crosscon# make -C CROSSCON-Hypervisor/ \
	PLATFORM=rpi4 \
	CONFIG_BUILTIN=y \
	CONFIG_REPO=$CONFIG_REPO \
	CONFIG=rpi4-single-vTEE \
	OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
	CROSS_COMPILE=aarch64-none-elf- \
        -j`nproc`
```

After executing these commands, the binary will be at the following path on the
container:

```bash
root@565810a48049:/work/crosscon# realpath CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin
/work/crosscon/CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin
root@565810a48049:/work/crosscon#
```

The second-to-last step is to copy it over to host, then onto the SD card:

```bash
docker cp crosscon_hv_container:/work/crosscon/CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin .
cp crossconhyp.bin /run/media/$USER/boot/
```

!!! note

    The SD card doesn't necessarily have to be mounted at
    `/run/media/$USER/boot`, so make sure to check where it's actually mounted
    by using `lsblk` and checking the location.

And finally the second partition (the one containing the rootfs) has to be
mounted. This is necessary in order to edit the `/etc/fstab` file, which tells
the kernel where the `/boot` partition is.

Once the second partition has been mounted, make sure the `/etc/fstab` file
looks exactly like this (this command assumes that the second partition
has been manually mounted using `mount` at `/mnt` directory):

```bash
user in ~ λ cat /mnt/etc/fstab
# stock fstab - you probably want to override this with a machine specific one

/dev/root            /                    auto       defaults              1  1
proc                 /proc                proc       defaults              0  0
devpts               /dev/pts             devpts     mode=0620,ptmxmode=0666,gid=5      0  0
tmpfs                /run                 tmpfs      mode=0755,nodev,nosuid,strictatime 0  0
tmpfs                /var/volatile        tmpfs      defaults              0  0

# uncomment this if your device has a SD/MMC/Transflash slot
#/dev/mmcblk0p1       /media/card          auto       defaults,sync,noauto  0  0

/dev/mmcblk1p1	/boot	vfat	defaults	0	0
user in ~ λ
```

By default, `/boot` is specified for `/dev/mmcblk0p1`, which works for the
purpose of using Zarhus OS without the CROSSCON Hypervisor, but in this case
it has to be edited to point to the correct partition, which is
`/dev/mmcblk1p1`

The final setup for connections and booting is the same as in the
[last steps of the Hypervisor demo](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/blob/67eb25c97dda2457ca08fa1a10ea68c9c6095b05/rpi4-ws/README.md#setup-board).

## Booting

Here are example logs from booting the whole setup:

```bash
wgrzywacz in ~ λ minicom -D /dev/ttyUSB0

Welcome to minicom 2.9

OPTIONS: I18n
Compiled on Jul 18 2024, 00:00:00.
Port /dev/ttyUSB0, 18:05:11

Press CTRL-A Z for help on special keys

7.9 GiB
RPI 4 Model B (0xd03115)
Core:  209 devices, 16 uclasses, devicetree: board
MMC:   mmcnr@7e300000: 1, mmc@7e340000: 0
Loading Environment from FAT... Unable to read "uboot.env" from mmc0:1...
In:    serial
Out:   serial
Err:   serial
Net:   eth0: ethernet@7d580000
PCIe BRCM: link up, 5.0 Gbps x1 (SSC)
starting USB...
Bus xhci_pci: Register 5000420 NbrPorts 5
Starting the controller
USB XHCI 1.00
scanning bus xhci_pci for devices... 2 USB Device(s) found
       scanning usb for storage devices... 0 Storage Device(s) found
Hit any key to stop autoboot:  0
U-Boot> fatload mmc 0 0x200000 crossconhyp.bin; go 0x200000
28650920 bytes read in 1217 ms (22.5 MiB/s)
## Starting application at 0x00200000 ...

   _____ _____   ____   _____ _____  _____ ____  _   _
  / ____|  __ \ / __ \ / ____/ ____|/ ____/ __ \| \ | |
 | |    | |__) | |  | | (___| (___ | |   | |  | |  \| |
 | |    |  _  /| |  | |\___ \\___ \| |   | |  | | . ` |
 | |____| | \ \| |__| |____) |___) | |___| |__| | |\  |
  \_____|_|  \_\\____/|_____/_____/ \_____\____/|_| \_|
  _    _                             _
 | |  | |                           (_)
 | |__| |_   _ _ __    ___ _ ____   ___ ___  ___  _ __
 |  __  | | | | '_ \ / _ \ '__\ \ / / / __|/ _ \| '__|
 | |  | | |_| | |_) |  __/ |   \ V /| \__ \ (_) | |
 |_|  |_|\__, | .__/ \___|_|    \_/ |_|___/\___/|_|
          __/ | |
         |___/|_|

CROSSCONHYP INFO: Initializing VM 1
CROSSCONHYP INFO: VM 1 adding memory region, VA 0x10100000 size 0xf00000
CROSSCONHYP INFO: VM 1 adding MMIO region, VA: 0xfe215000 size: 0xfe215000 mapped at 0xfe215000
CROSSCONHYP INFO: VM 1 adding IPC for shared memory 0 at VA: 0x8000000  size: 0x200000
CROSSCONHYP INFO: VM 1 adding memory region, VA 0x8000000 size 0x200000
CROSSCONHYP INFO: VM 1 is sdTZ (OP-TEE)
CROSSCONHYP INFO: Initializing VM 2
CROSSCONHYP INFO: VM 2 adding memory region, VA 0x20000000 size 0x40000000
CROSSCONHYP INFO: VM 2 adding MMIO region, VA: 0xfc000000 size: 0xfc000000 mapped at 0xfc000000
CROSSCONHYP INFO: VM 2 adding MMIO region, VA: 0x600000000 size: 0x600000000 mapped at 0x600000000
CROSSCONHYP INFO: VM 2 adding MMIO region, VA: 0x0 size: 0x0 mapped at 0x0
CROSSCONHYP INFO: VM 2 assigning interrupt 32

#####################################
# assigning lots of interrupts here #
#####################################

CROSSCONHYP INFO: VM 2 assigning interrupt 214
CROSSCONHYP INFO: VM 2 assigning interrupt 215
CROSSCONHYP INFO: VM 2 adding MMIO region, VA: 0x7d580000 size: 0x7d580000 mapped at 0x7d580000
CROSSCONHYP INFO: VM 2 assigning interrupt 0
CROSSCONHYP INFO: VM 2 assigning interrupt 4
CROSSCONHYP INFO: VM 2 assigning interrupt 157
CROSSCONHYP INFO: VM 2 assigning interrupt 158
CROSSCONHYP INFO: VM 2 adding MMIO region, VA: 0x0 size: 0x0 mapped at 0x0
CROSSCONHYP INFO: VM 2 assigning interrupt 27
CROSSCONHYP INFO: VM 2 adding IPC for shared memory 0 at VA: 0x8000000  size: 0x200000
CROSSCONHYP INFO: VM 2 adding memory region, VA 0x8000000 size 0x200000
CROSSCONHYP INFO: VM 2 is sdGPOS (normal VM)
CROSSCONHYP INFO: VM 1 is parent of VM 2
[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x410fd083]
[    0.000000] Linux version 6.6.22-v8 (oe-user@oe-host) (aarch64-zarhus-linux-gcc (GCC) 13.2.0, GNU ld (GNU Binutils) 2.42.0.20240216) #1 SMP PREEMPT Tue Mar 19 17:41:59 UTC 2024
[    0.000000] KASLR disabled due to lack of seed
[    0.000000] Machine model: Raspberry Pi 4 Model B
[    0.000000] earlycon: bcm2835aux0 at MMIO32 0x00000000fe215040 (options '115200n8')

#######################
# kernel booting here #
#######################

[    3.458439] NET: Registered PF_INET6 protocol family
[    3.464407] Segment Routing with IPv6
[    3.468641] In-situ OAM (IOAM) with IPv6
[    3.512847] systemd[1]: systemd 255.4^ running in system mode (-PAM -AUDIT -SELINUX -APPARMOR +IMA -SMACK +SECCOMP -GCRYPT -GNUTLS -OPENSSL +ACL +BLKID -CURL -ELFUTILS -FIDO2 -IDN2 -IDN)
[    3.545778] systemd[1]: Detected architecture arm64.

Welcome to Distro for Zarhus product 0.1.0 (scarthgap)!

[    3.586925] systemd[1]: Hostname set to <raspberrypi4-64>.
[    3.601562] systemd[1]: Initializing machine ID from random generator.
[    3.752948] systemd-sysv-generator[80]: SysV service '/etc/init.d/tee-supplicant' lacks a native systemd unit file. ~ Automatically generating a unit file for compatibility. Please upda!

#######################
# kernel booting here #
#######################

[  OK  ] Started User Login Management.
[  OK  ] Reached target Multi-User System.
[    9.925333] Bluetooth: HCI socket layer initialized
[    9.953580] Bluetooth: L2CAP socket layer initialized
        [    9.977993] Bluetooth: SCO socket layer initialized
 Starting Record Runlevel Change in UTMP...
[  OK  ] Finished Record Runlevel Change in UTMP.
[   10.189851] brcmfmac: brcmf_cfg80211_set_power_mgmt: power save enabled
[  OK  ] Finished OpenSSH Key Generation.

Distro for Zarhus product 0.1.0 raspberrypi4-64 ttyS1

raspberrypi4-64 login:
[   16.227830] IPv4: martian source 255.255.255.255 from 192.168.10.1, on dev end0
[   16.235768] ll header: 00000000: ff ff ff ff ff ff 78 9a 18 13 76 6d 08 00
root
root@raspberrypi4-64:~#
root@raspberrypi4-64:~#
root@raspberrypi4-64:~# ls
root@raspberrypi4-64:~#
```
