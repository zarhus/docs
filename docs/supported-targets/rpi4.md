# Raspberry Pi 4

## Description and Resources

The Raspberry Pi 4 is a versatile single-board computer suitable for a wide
range of applications. This guide walks through building Zarhus OS using
`meta-zarhus`, flashing the OS onto an SD card, and accessing the device
via UART for debugging.

Additional resources for the Raspberry Pi 4:

* [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
* [Raspberry Pi GPIO Pinout](https://www.raspberrypi.com/documentation/computers/images/GPIO-Pinout-Diagram-2.png?hash=df7d7847c57a1ca6d5b2617695de6d46)

## Zarhus OS Setup

### Build Zarhus OS

1. Clone the `meta-zarhus` repository:

    ```sh
    git clone https://github.com/zarhus/meta-zarhus
    ```

2. Follow the instructions in the repository's
[building guide](../getting-started/building.md) to build Zarhus OS for
Raspberry Pi 4.

Once built, you can move onto flashing.

### Flash Zarhus OS Image to SD Card

To flash the image to the SD card:

    ```sh
    cd build/tmp/deploy/images/raspberrypi4
    sudo bmaptool copy --bmap zarhus-base-image-debug-raspberrypi4.rootfs.wic.bmap zarhus-base-image-debug-raspberrypi4.rootfs.wic.gz /dev/sdc
    ```

Replace `/dev/sdX` with your SD card device (e.g. `/dev/sdb`).
Ensure you are writing to the correct device.

## UART Console Access

### Hardware Setup

To connect via UART for debugging:

1. Use a UART-to-USB adapter and connect it to the Raspberry Pi 4 GPIO pins:

    | GPIO Pin | Description  |
    |----------|--------------|
    | Pin 6    | GND          |
    | Pin 8    | UART TXD     |
    | Pin 10   | UART RXD     |

    Refer to the
    [Raspberry Pi GPIO Pinout](https://www.raspberrypi.com/documentation/computers/images/GPIO-Pinout-Diagram-2.png?hash=df7d7847c57a1ca6d5b2617695de6d46)
    for the full pinout.

2. Plug the USB end into your host machine.

### Software Setup

1. Install a terminal program (e.g., `minicom` for Linux).

2. Launch `minicom` on a Linux host to connect to the RPi4:

    ```sh
    minicom -D /dev/ttyUSBX
    ```

    Also make sure `Hardware Flow Control` is off (`CTRL-A`, then `Z` to
    open the menu, then `O` to `Configure minicom`, then choose
    `Serial port setup`, then (if it's enabled) press `F` to
    disable `Hardware Flow Control`).

3. You should now see the Zarhus OS boot console.

From this point, you can login (login `root`) to monitor and debug the
Raspberry Pi 4 running Zarhus OS.
