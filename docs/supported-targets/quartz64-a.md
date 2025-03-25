# Quartz64 Model A

## Description and resources

The [Quartz64 Model A](https://pine64.org/devices/quartz64_model_a/) is a SBC
based on Rockchip RK3566 and produced by PINE64.

Additional resources for the board:

* [PINE64
documentation;](https://pine64.org/documentation/Quartz64/Further_information/Schematics_and_certifications/)
* [PINE64 Wiki](https://wiki.pine64.org/wiki/Quartz64)
* [Rockchip Wiki: partitions map;](https://opensource.rock-chips.com/wiki_Partitions)
* [Rockchip Wiki: boot flow.](https://opensource.rock-chips.com/wiki_Boot_option#Boot_introduce)

## Serial port access (Zarhus OS debug console)

Numerous types of software can be used to communicate via serial ports. On a
host machine with Linux-based OS it can be `minicom`, Windows users can access
that with [PuTTY](https://www.putty.org/).

There are only two parameters that depend not only on hardware but on software
as well: baudrate and serial port number. In case of Quartz64 Model A port -
Zarhus OS gives access to console via serial port 2 with baudrate `1.5 Mbps`, so
you can connect to the console by connecting the UART adapter to pins `8`, `10`
and `10` of
[`CON40`](https://files.pine64.org/doc/quartz64/Quartz64_model-A_schematic_v2.0_20210427.pdf)

And use following command on your host Linux distribution:

```bash
$ minicom -b 1500000 -D /dev/ttyUSBX
```

Where instead of `/dev/ttyUSBX` there should be the name of your UART adapter
under your host Linux distribution.

## Zarhus OS image building and flashing

For building steps check the [generic Zarhus OS building
guide.](../getting-started/building.md)

For flashing steps check the [generic Zarhus OS SD card flashing
guide.](../getting-started/flashing.md)

You can verify the booted image by follwoing [generic Zarhus OS image
verification.](../getting-started/verification.md)
