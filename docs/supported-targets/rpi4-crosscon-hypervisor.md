# Raspberry Pi 4 for the CROSSCON Hypervisor

This guide provides info on how to boot a working linux system
with mounted `rootfs`, `systemd` services working, and a login
console that lets the user execute commands on a Raspberry Pi 4
device running the CROSSCON Hypervisor.

## Build CROSSCON Hypervisor

We recommend first following the
[default demo](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws/)
using the
[docker environment](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/pull/1)
to isolate the dependencies.

Make sure to copy over the contents of the SD card somewhere, so that
they are not lost - they will be needed later.

## Build Zarhus

Obviously, Zarhus will also have to be built (on the host).
Make sure to run this exact build command:

```bash
SHELL=/bin/bash KAS_MACHINE=raspberrypi4-64 kas-container build meta-zarhus/kas/common.yml:meta-zarhus/kas/cache.yml:meta-zarhus/kas/debug.yml:meta-zarhus/kas/rpi.yml
```

The `KAS_MACHINE` variable is very important here, `raspberrypi4` would build a 32-bit
version of the system - we need to use `raspberrypi4-64` in order to get a 64-bit
version, so that it's compatible with the hypervisor.

## Combine the two

When the Zarhus build finishes, flash the SD card with it like this:

```bash
cd build/tmp/deploy/images/raspberrypi4-64/
sudo bmaptool copy --bmap zarhus-base-image-debug-raspberrypi4-64.rootfs.wic.bmap zarhus-base-image-debug-raspberrypi4-64.rootfs.wic.gz /dev/sd[X]
```

(replace `/dev/sd[X]` with the actual card). Once that finishes, reinsert the card
and delete everything from the `/boot` partition, and replace it with the contents
produced by the CROSSCON Hypervisor demo step above.

We also need to swap the kernel for the Zarhus kernel. It can be done by first copying
the kernel to our container (make sure to copy the actual kernel, not the symlink):

```bash
cd build/tmp/deploy/images/raspberrypi4-64/
file Image # use the output of this command for the next one
docker cp Image-1-6.6.22+git0+6a24861d65_c04af98514-r0-raspberrypi4-64-20250226164115.bin crosscon_hv_container:/work/Image
```

We will have to recompile the Hypervisor, starting from step 9 of the original demo.

First apply this change to the device tree file in `rpi4-ws` folder:

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

then run these commands:

```bash
cd /work/crosscon
dtc -I dts -O dtb rpi4-ws/rpi4.dts > rpi4-ws/rpi4.dtb
rm linux-rpi4.bin
rm linux-rpi4.elf
make  \
    IMAGE=/work/Image \
    DTB=../rpi4-ws/rpi4.dtb \
    TARGET=linux-rpi4.bin \
    CROSS_COMPILE=aarch64-none-elf- \
    ARCH=aarch64
```

notice that this step has changed, so instead of using the kernel
from `linux/build-aarch64/arch/arm64/boot/` we use the kernel from
our yocto deploy directory.

Now we are almost ready to build the Hypervisor - just one more change
needs to be applied:

```git
root@565810a48049:/work/crosscon/CROSSCON-Hypervisor# git diff src/arch/armv8/aborts.c
diff --git a/src/arch/armv8/aborts.c b/src/arch/armv8/aborts.c
index a7f5adc..503dc30 100644
--- a/src/arch/armv8/aborts.c
+++ b/src/arch/armv8/aborts.c
@@ -43,6 +43,7 @@ void internal_abort_handler(uint64_t gprs[]) {

 void aborts_data_lower(uint64_t iss, uint64_t far, uint64_t il)
 {
+    printk("magic printk\n");
     if (!(iss & ESR_ISS_DA_ISV_BIT) || (iss & ESR_ISS_DA_FnV_BIT)) {
         ERROR("no information to handle data abort (0x%x)", far);
     }
root@565810a48049:/work/crosscon/CROSSCON-Hypervisor#
```

this additional `printk` prevents keeps the UART output going, so that
the console can be accessed.

Now we can re-run the commands needed to build the Hypervisor:

```bash
CONFIG_REPO=/work/crosscon/rpi4-ws/configs
cd /work/crosscon

make -C CROSSCON-Hypervisor/ \
	PLATFORM=rpi4 \
	CONFIG_BUILTIN=y \
	CONFIG_REPO=$CONFIG_REPO \
	CONFIG=rpi4-single-vTEE \
	OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
	CROSS_COMPILE=aarch64-none-elf- \
        clean

make -C CROSSCON-Hypervisor/ \
	PLATFORM=rpi4 \
	CONFIG_BUILTIN=y \
	CONFIG_REPO=$CONFIG_REPO \
	CONFIG=rpi4-single-vTEE \
	OPTIMIZATIONS=0 \
        SDEES="sdSGX sdTZ" \
	CROSS_COMPILE=aarch64-none-elf- \
        -j`nproc`
```

after executing these commands, the binary will be at this path:

```bash
/work/crosscon/CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin
```

The last step is to copy it over to host, then onto the SD card:

```bash
docker cp crosscon_hv_container:/work/crosscon/CROSSCON-Hypervisor/bin/rpi4/builtin-configs/rpi4-single-vTEE/crossconhyp.bin .
cp crossconhyp.bin /run/media/$USER/boot/ # or wherever the SD card is mounted
```

Finally, the setup for connections and booting is the same as in the
[last steps of the Hypervisor demo](https://github.com/crosscon/CROSSCON-Hypervisor-and-TEE-Isolation-Demos/tree/master/rpi4-ws/#setup-board).
