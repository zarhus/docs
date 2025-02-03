# Building Zarhus OS

<!--
TODO: scalable way to build different images (e.g. with WebKit or without
WebKit support) for different platforms.
-->

This guide will demonstrate how to build a Zarhus OS image from zero!

## Prerequisites

* Linux PC (tested on `Fedora 40`)
* [docker](https://docs.docker.com/engine/install/fedora/) installed
* [kas-container
  3.0.2](https://raw.githubusercontent.com/siemens/kas/3.0.2/kas-container)
  script downloaded and available in
  [PATH](https://en.wikipedia.org/wiki/PATH_(variable)).

    ```bash
    mkdir ~/.local/bin
    wget -O ~/.local/bin/kas-container https://raw.githubusercontent.com/siemens/kas/3.0.2/kas-container
    chmod +x ~/.local/bin/kas-container
    ```

!!! note

    You may need to add `~/.local/bin` into your
    [PATH](https://en.wikipedia.org/wiki/PATH_(variable)). You can do so for
    example by adding `export PATH=$PATH:~/.local/bin` to your `.bashrc` and
    `source` it.

* `meta-zarhus` repository cloned:

    ```bash
    mkdir yocto
    cd yocto
    git clone https://github.com/zarhus/meta-zarhus.git
    ```

* [`bmaptool`](https://docs.yoctoproject.org/dev-manual/bmaptool.html)
  installed:

    ```bash
    sudo dnf install bmap-tools
    ```

!!! note

    You can also use `bmaptool` [from
    GitHub](https://github.com/yoctoproject/bmaptool) if it is not available in
    your distro.

## Build

Depending on which features you want to have in your build, pass the desired
`.yml` files via command line. You can read more on that in
[kas documentation.](https://kas.readthedocs.io/en/latest/userguide/project-configuration.html#including-configuration-files-via-the-command-line)
The files should be passed in a specific order. The file which is passed after
some file will override settings set by the previously-passed file.

Currently, the following files are present in `meta-zarhus/kas`:

* `common.yml`: common configuration file, should be included in all builds;
* `cache.yml`: file for cache mirrors configuration;
* `debug.yml`: adds debug functionalities into the final image;
* `rockchip.yml`: Rockchip-specific target configuration file, should be used
  for Rockchip builds;
* `webkit.yml`: includes Webkit and some additional functionalities into build.
* `rpi.yml`: includes a layer necessary for Raspberry Pi boards, as well
  necessary config.

Then check BSP layers for available target platform (target platforms configs
are located in `conf/machine` directory of every BSP layer) and choose one.
Then, from `yocto` directory run:

```shell
SHELL=/bin/bash KAS_MACHINE=<TARGET_NAME> kas-container build <KAS_FILES>
```

!!! note

    Replace `<TARGET_NAME>` with the name of the chosen target
    configuration file, and `<KAS_FILES>` with a list of kas files, separated by
    `:`.

For example:

```shell
SHELL=/bin/bash KAS_MACHINE=orangepi-cm4 kas-container build meta-zarhus/kas/common.yml:meta-zarhus/kas/rockchip.yml
```

* Image build takes time, so be patient and after build's finish you should see
something similar to (the exact tasks numbers may differ):

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

You should find an image with filename ending with `.rootfs.wic.gz` and a binary
map for the image in format with filename ending with `.rootfs.wic.bmap`. These
files will be needed for [flashing process](./flashing.md).
