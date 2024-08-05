# Flashing Zarhus OS

There are many ways an OS can be flashed and booted on embedded platform, but
the most common one is using an SD card. This guide will describe SD card
flashing only, because all other ways to flash the image are highly
target-specific and are described [per-target](../supported-targets/targets.md).

## Flashing SD card

This section demonstrates how to flash a Zarhus OS image on the SD card.

### Prerequisites

* Linux PC (tested on `Ubuntu 20.04 LTS`);
* [bmaptool](https://source.tizen.org/documentation/reference/bmaptool)
  installed:

    ```bash
    sudo apt install bmap-tools
    ```

* Zarhus OS image built according to [build guide](./building.md).

!!! note

    You can also use `bmap-tools` [from
    GitHub](https://github.com/intel/bmap-tools) if it is not available in your
    distro.

### Flashing

Find out your device name:

```shell
$ fdisk -l
(...)
Device     Boot  Start    End Sectors  Size Id Type
/dev/sdx1  *      8192 131433  123242 60,2M  c W95 FAT32 (LBA)
/dev/sdx2       139264 186667   47404 23,2M 83 Linux
```

!!! warning

    In this case the device name is `/dev/sdx` **but be aware, in next steps
    replace `/dev/sdx` with the right device name on your platform or else you
    can damage your system!**

From the directory you ran your image build, run command:

```shell
$ cd build/tmp/deploy/images/MACHINE_NAME
$ sudo umount /dev/sdx*
$ sudo bmaptool copy --bmap IMAGE_NAME-IMAGE_TYPE-MACHINE_NAME.rootfs.wic.bmap IMAGE_NAME-IMAGE_TYPE-MACHINE_NAME.rootfs.wic.gz /dev/sdx
```

!!! note

    Replace `MACHINE_NAME` with the name of the machine you have built the image
    for, `IMAGE_TYPE` with `debug` or `prod` and `IMAGE_NAME` with the name of
    the image you have built.

You should see output similar to this:

```shell
bmaptool: info: block map format version 2.0
bmaptool: info: 85971 blocks of size 4096 (335.8 MiB), mapped 42910 blocks (167.6 MiB or 49.9%)
bmaptool: info: copying image 'zarhus-base-image-debug-zarhus-machine-cm3.rootfs.wic.gz' to block device '/dev/sdx' using bmap file 'zarhus-base-image-debug-zarhus-machine-cm3.rootfs.wic.bmap'
bmaptool: info: 100% copied
bmaptool: info: synchronizing '/dev/sdx'
bmaptool: info: copying time: 11.1s, copying speed 15.1 MiB/sec
```

## Verification

After the SD card has been flashed with your image, the partitions (at least
`rootfs` partition) should  be mountable. So, you can mount a partition and
explore the Zarhus OS without even booting it! Here is example block storage
layout after flashing [Zarhus Rockchip OS
image](https://github.com/zarhus/meta-zarhus-bsp-rockchip/blob/main/wic/sdimage-rockchip.wks):

```bash
$ lsblk
(...)
sdx                                             8:16   1  14.8G  0 disk
├─sdx1                                          8:17   1   3.5M  0 part
├─sdx2                                          8:18   1   256K  0 part
├─sdx3                                          8:19   1   192K  0 part
├─sdx4                                          8:20   1    32K  0 part
├─sdx5                                          8:21   1    32K  0 part
├─sdx6                                          8:22   1     4M  0 part
├─sdx7                                          8:23   1     4M  0 part
├─sdx8                                          8:24   1     4M  0 part
└─sdx9                                          8:25   1 320.7M  0 part
(...)
```

!!! note

    Your SD card may get another file name in your system, here `sdx` is shown
    as an example.

Mounting `rootfs`:

```bash
$ sudo mount /dev/sdx9 /mnt
$ ls /mnt
bin  boot  dev  etc  home  lib  lost+found  media  mnt  proc  root  run  sbin  srv  sys  tmp  usr  var
$ lsblk
(...)
sdx                                             8:16   1  14.8G  0 disk
├─sdx1                                          8:17   1   3.5M  0 part
├─sdx2                                          8:18   1   256K  0 part
├─sdx3                                          8:19   1   192K  0 part
├─sdx4                                          8:20   1    32K  0 part
├─sdx5                                          8:21   1    32K  0 part
├─sdx6                                          8:22   1     4M  0 part
├─sdx7                                          8:23   1     4M  0 part
├─sdx8                                          8:24   1     4M  0 part
└─sdx9                                          8:25   1 320.7M  0 part  /mnt
(...)
```

For further image verification checkout [verification guide](./verification.md).
