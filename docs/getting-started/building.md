# Building Zarhus OS

<!--
TODO: scalable way to build different images (e.g. with WebKit or without
WebKit support) for different platforms.
-->

This guide will demonstrate how to build a Zarhus OS image from zero!

## Prerequisites

* Linux PC (tested on `Ubuntu 20.04 LTS`)
* [docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/) installed
* [kas-container
  3.0.2](https://raw.githubusercontent.com/siemens/kas/3.0.2/kas-container)
  script downloaded and available in
  [PATH](https://en.wikipedia.org/wiki/PATH_(variable)).

    ```bash
    mkdir ~/.local/bin
    wget -O ~/.local/bin/kas-container https://raw.githubusercontent.com/siemens/kas/2.6.3/kas-container
    chmod +x ~/.local/bin/kas-container
    ```

* `meta-zarhus` repository cloned:

    ```bash
    mkdir yocto
    cd yocto
    git clone https://github.com/zarhus/meta-zarhus.git
    ```

* [`bmaptool`](https://source.tizen.org/documentation/reference/bmaptool) installed:

    ```bash
    sudo apt install bmap-tools
    ```

!!! note

    You can also use `bmap-tools` [from
    GitHub](https://github.com/intel/bmap-tools) if it is not available in your
    distro.

## Build

From `yocto` directory run:

```shell
$ SHELL=/bin/bash kas-container build meta-zarhus/kas-IMAGE_TYPE.yml
```

!!! note

    Replace `IMAGE_TYPE` with either `debug` or `prod`.

Image build takes time, so be patient and after the build finishes you should see
something similar to this (the exact tasks numbers may differ):

```shell
Initialising tasks: 100% |###########################################################################################| Time: 0:00:01
Sstate summary: Wanted 2 Found 0 Missed 2 Current 931 (0% match, 99% complete)
NOTE: Executing Tasks
NOTE: Tasks Summary: Attempted 2532 tasks of which 2524 didn't need to be rerun and all succeeded.
```

# Verification

The build should finish without errors or warnings.

After the build has finished - feel free to explore
`yocto/build/tmp/deploy/images/MACHINE_NAME/` directory for built images.

!!! note

    Replace `MACHINE_NAME` with the name of the machine you have built your
    image for.

You should find an image in formate `.rootfs.wic.gz` and a binary map for the
image in format `.rootfs.wic.bmap`. These files will be needed for
[flashing process](./flashing.md).
