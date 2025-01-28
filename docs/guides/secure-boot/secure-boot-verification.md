# Verifying Secure Boot

## Prerequisites

* Restore BIOS to defaults.
    <!--
    Does it also restore SB keys?
    if not then SBO006.001 + restore should probably be first test so we start
    from known state
    -->
* Attached USB drive prepared in [USB drive](#usb-drive) section
    - If using QEMU `tests.img` can be attached directly e.g. via adding
        `-drive if=ide,file=tests.img` argument to `qemu` command

* Before starting tests please boot to OS on machine to be tested, mount
    USB drive and run `add-boot-options.sh` script. It should add all `.efi`
    files to boot options

### USB drive

1. Download [generate-image.sh](./generate-image.sh)
1. Build [LockDown.efi](#lockdownefi) file
1. Build [hello.efi](#helloefi) file
1. Run `generate-image.sh` script. It'll generate `tests.img` file containing
needed files and certificates
1. Flash this file to USB drive

#### LockDown.efi

**Dependencies**

* [kas-container](https://docs.dasharo.com/dasharo-tools-suite/documentation/building/#prerequisites)
* [git](https://git-scm.com/)

**Steps**

1. Clone and checkout tag `v1.2.23`

    ```shell
    git clone --depth 1 --branch v1.2.23 https://github.com/Dasharo/meta-dts.git
    ```

1. Build `efitools` recipe which will build `LockDown.efi` with sample keys

    ```shell
    SHELL=/bin/bash kas-container shell meta-dts/kas-uefi-sb.yml -c "bitbake efitools"`
    ```

1. Copy `LockDown.efi` to directory containing `generate-image.sh` script.</br>
File should be inside `build/tmp/deploy/images/genericx86_64` directory.</br>
Sample keys and certificates used in `LockDown.efi` can be viewed in
`build/tmp/deploy/images/genericx86_64/sample-keys/uefi_sb_keys`

#### hello.efi

**Dependencies**

* [Docker](https://docs.docker.com/engine/install/)
* [git](https://git-scm.com/)

**Steps**

1. Pull docker image that'll contain tools needed to build `hello.efi`
<https://github.com/tianocore/containers?tab=readme-ov-file#Current-Status>.

    ```shell
    docker pull ghcr.io/tianocore/containers/fedora-39-build:46802aa
    ```

1. Get source code for EDK2

    ```shell
    git clone --depth 1 --recurse-submodules --shallow-submodules --branch edk2-stable202408 https://github.com/tianocore/edk2.git
    ```

1. Add sleep (in this case 2 seconds) to `HelloWorld.c` otherwise output will
disappear too fast for human to see

    ```shell
    cd edk2
    git apply <<EOF
    diff --git a/MdeModulePkg/Application/HelloWorld/HelloWorld.c b/MdeModulePkg/Application/HelloWorld/HelloWorld.c
    index 9b77046e561c..ebd4ad9d6a79 100644
    --- a/MdeModulePkg/Application/HelloWorld/HelloWorld.c
    +++ b/MdeModulePkg/Application/HelloWorld/HelloWorld.c
    @@ -56,5 +56,6 @@ UefiMain (
         }
       }

    +  SystemTable->BootServices->Stall(2000000);
       return EFI_SUCCESS;
     }
    EOF
    ```

1. Build `HelloWorld.efi`

    ```shell
    docker run -v $(pwd):/edk2 -w /edk2 --entrypoint bash --rm \
        ghcr.io/tianocore/containers/fedora-39-build:46802aa -c ' \
            source edksetup.sh && make -C BaseTools && build -a X64 -t GCC5 \
                -p MdeModulePkg/MdeModulePkg.dsc \
                -m MdeModulePkg/Application/HelloWorld/HelloWorld.inf -b RELEASE'
    ```

    Build should complete with

    ```text
    (...)
    - Done -
    Build end time: 12:51:06, Oct.04 2024
    Build total time: 00:00:06
    ```

1. Copy built `HelloWorld.efi` file to directory with `generate-image.sh` and
rename it to `hello.efi`

    ```shell
    cp Build/MdeModule/RELEASE_GCC5/X64/HelloWorld.efi <replace/this/path/>hello.efi
    ```

#### USB directory layout

```text
.
├── add-boot-options.sh
├── SBO003.001
│   ├── cert.der
│   └── hello.efi
├── SBO004.001
│   ├── cert.der
│   └── hello.efi
├── SBO008.001
│   ├── cert.der
│   └── hello.efi
├── SBO009.001
│   ├── cert.der
│   └── hello.efi
├── SBO010.001
│   ├── cert.der
│   └── hello.efi
├── SBO010.002
│   ├── cert.der
│   └── hello.efi
├── SBO010.003
│   ├── cert.der
│   └── hello.efi
├── SBO010.004
│   ├── cert.der
│   └── hello.efi
├── SBO010.005
│   ├── cert.der
│   └── hello.efi
├── SBO010.006
│   ├── cert.der
│   └── hello.efi
├── SBO011.001
│   ├── cert.der
│   └── hello.efi
├── SBO013.001
│   ├── hello.efi
│   └── LockDown.efi
└── SBO013.002
    └── KEK.crt

14 directories, 26 files
```

## Tests

On ODROID-H4, BIOS version ADLN-H4 1.05 there is a weird quirk in when you can
edit SB settings (e.g. state, adding certificates or restoring to default).
It's described in more details on
[ODROID forum](https://forum.odroid.com/viewtopic.php?f=173&t=49144).
Due to that you should reboot platform before each test.

<!-- more on https://forum.odroid.com/viewtopic.php?f=173&t=49144 -->

### SBO002.001 Secure Boot can be enabled from boot menu and is seen from OS

**Description**

This test verifies that Secure Boot can be enabled from the boot menu and, after
the platform reset, it is seen from the OS.

**Steps**

1. [Enable Secure Boot](./secure-boot-bios.md#enable-secure-boot)
1. Save changes and reboot platform
1. Boot and log into OS
1. Enter the following command and note the output

    ```shell
    dmesg | grep "Secure boot"
    ```

**Expected result**:

```text
secureboot: Secure boot enabled
```

<!--
    Another way:

    ```shell
    mokutil --sb-state
    SecureBoot enabled
    ```
-->

### SBO003.001 Attempt to boot file signed with the correct key

<!--
Maybe add test before this one, that checks that file won't boot before adding
certificate
-->

**Description**

This test verifies that Secure Boot allows booting a signed file with a correct
key.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO003.001/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO003.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO004.001 Attempt to boot unsigned file

**Description**

This test verifies that Secure Boot blocks booting unsigned file.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Boot SBO004.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Booting file should fail with Secure Boot error e.g.:

```text
/---------- Secure Boot Violation ----------\
|                                           |
| Invalid signature detected. Check Secure  |
|           Boot Policy in Setup            |
|                                           |
|-------------------------------------------|
|                    Ok                     |
\-------------------------------------------/
```

### SBO006.001 Reset Secure Boot Keys option availability

**Description**

This test aims to verify, that the Reset Secure Boot Keys option is available

**Prerequisites**

**Steps**

1. [Enter Secure Boot key management menu](./secure-boot-bios.md#enter-secure-boot-key-management-menu)

**Expected result**

Option to restore SB keys should be available e.g.

```text
Restore Factory Keys
```

### SBO007.001 Attempt to boot the file after restoring keys to default

**Description**

This test verifies that the Reset Secure Boot Keys option works correctly.

**Prerequisites**

* [SBO003.001](#sbo003001-attempt-to-boot-file-signed-with-the-correct-key)
    succeeded
* [SBO006.001](#sbo006001-reset-secure-boot-keys-option-availability)
    succeeded
* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Enter Secure Boot key management menu](./secure-boot-bios.md#enter-secure-boot-key-management-menu)
1. Select option to restore Secure Boot keys e.g. `Restore Factory Keys`
and accept
1. Save changes and reboot platform
1. [Boot SBO003.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Booting file should fail with Secure Boot error e.g.:

```text
/---------- Secure Boot Violation ----------\
|                                           |
| Invalid signature detected. Check Secure  |
|           Boot Policy in Setup            |
|                                           |
|-------------------------------------------|
|                    Ok                     |
\-------------------------------------------/
```

### SBO008.001 Attempt to enroll the key in the incorrect format

**Description**

This test verifies that Secure Boot doesn't allow enrolling keys in the
incorrect format

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO008.001/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)

**Expected result**

Adding certificate should end in failure e.g.

```text
┌── Append  ───┐
│              │
│    Failed    │
│              │
├──────────────┤
│      Ok      │
└──────────────┘
```

### SBO009.001 Attempt to boot file signed for intermediate certificate

**Description**

This test verifies that a file signed with an intermediate certificate can be
executed.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO009.001/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO009.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.001 Check support for rsa2k signed certificates

<!-- we can probably skip this one as it's identical to SBO003.001 -->

**Description**

This test verifies that a Secure Boot supports RSA2048 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.001/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO010.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.002 Check support for rsa3k signed certificates

**Description**

This test verifies that a Secure Boot supports RSA3072 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.002/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO010.002/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.003 Check support for rsa4k signed certificates

**Description**

This test verifies that a Secure Boot supports RSA4096 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.003/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO010.003/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.004 Check support for ecdsa256 signed certificates

**Description**

This test verifies that a Secure Boot supports ESCDA256 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.004/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO010.004/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.005 Check support for ecdsa384 signed certificates

**Description**

This test verifies that a Secure Boot supports ESCDA384 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.005/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO010.005/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.006 Check support for ecdsa521 signed certificates

**Description**

This test verifies that a Secure Boot supports ESCDA521 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.006/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot platform
1. [Boot SBO010.006/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO011.001 Attempt to enroll expired certificate and boot signed image

**Description**

This test verifies that an expired certificate cannot be used to boot image

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO011.001/cert.der to DB](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot
1. [Boot SBO011.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Booting file should fail with Secure Boot error e.g.:

```text
/---------- Secure Boot Violation ----------\
|                                           |
| Invalid signature detected. Check Secure  |
|           Boot Policy in Setup            |
|                                           |
|-------------------------------------------|
|                    Ok                     |
\-------------------------------------------/
```

### SBO014.001 Enroll certificates using sbctl

**Description**

This test erases Secure Boot keys from the BIOS menu and verifies if new keys
can be enrolled from the operating system using sbctl.

<!--
Changed this test a little because, based on original steps, test verified
that you can't boot OS after erasing SB keys and enrolling different ones.
If we want to verify that we can enroll keys from operating system then we
should `sbctl enroll-keys` followed by checking if those keys are visible from
BIOS. On Dasharo we can check PKCS7_GUID of KEK and DB (but not PK).
-->

**Prerequisites**

**Steps**

1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. If applicable disable key provisioning (e.g. AMI BIOS)
1. [Remove Secure Boot keys](./secure-boot-bios.md#remove-all-secure-boot-keys)
1. Save changes and restart platform
1. Boot and log into OS
1. Remove old Secure Boot keys

    ```shell
    rm -rf /usr/share/secureboot
    ```

1. Generate new Secure Boot keys

    ```shell
    $ sbctl create-keys
    Created Owner UUID 2a602183-aee8-4998-a313-25635405d554
    Creating secure boot keys...✓
    Secure boot keys created!
    ```

1. Enroll generated Secure Boot keys

    ```shell
    $ sbctl enroll-keys --yes-this-might-brick-my-machine
    Enrolling keys to EFI variables...✓
    Enrolled keys to the EFI variables!
    ```

1. Reboot platform
1. [Enter Secure Boot key management menu](./secure-boot-bios.md#enter-secure-boot-key-management-menu)
1. [Check enrolled KEK GUID](./secure-boot-bios.md#check-enrolled-keys)
1. [Check enrolled DB GUID](./secure-boot-bios.md#check-enrolled-keys)

**Expected result**

KEK and DB keys should have the same GUID as returned by `sbctl create-keys`
command e.g. `2a602183-aee8-4998-a313-25635405d554`

### SBO012.001 Boot OS Signed And Enrolled From Inside System

**Description**

This test verifies that OS boots after enrolling keys and signing system from
inside OS.

**Prerequisites**

* [SBO014.001](#sbo014001-enroll-certificates-using-sbctl) succeeded

**Steps**

1. Boot and log into OS
1. Sign all components

    ```shell
    $ sbctl verify | awk -F ' ' '{print $2}' | tail -n+2 | xargs -I @ sbctl sign "@"
    ✓ Signed /boot/efi/EFI/BOOT/BOOTX64.EFI
    ✓ Signed /boot/efi/EFI/BOOT/fbx64.efi
    ✓ Signed /boot/efi/EFI/BOOT/mmx64.efi
    ✓ Signed /boot/efi/EFI/ubuntu/grubx64.efi
    ✓ Signed /boot/efi/EFI/ubuntu/mmx64.efi
    ✓ Signed /boot/efi/EFI/ubuntu/shimx64.efi
    ```

1. Reboot platform
1. [Enable Secure Boot](./secure-boot-bios.md#enable-secure-boot)
1. Save changes and restart platform
1. Boot and log into OS
1. Verify that Secure Boot is enabled

    ```shell
    dmesg | grep "Secure boot"
    ```

**Expected result**

```text
secureboot: Secure boot enabled
```

<!--
    Another way:

    ```shell
    mokutil --sb-state
    SecureBoot enabled
    ```
-->

### SBO015.001 Attempt to enroll the key in the incorrect format with sbctl

**Description**

This test verifies that it is impossible to load a certificate in the wrong file
format from the operating system while using sbctl.

**Prerequisites**

**Steps**

1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. If applicable disable key provisioning (e.g. AMI BIOS)
1. [Remove Secure Boot keys](./secure-boot-bios.md#remove-all-secure-boot-keys)
1. Save changes and restart platform
1. Boot and log into OS
1. Remove old Secure Boot keys

    ```shell
    rm -rf /usr/share/secureboot
    ```

1. Generate new Secure Boot keys

    ```shell
    $ sbctl create-keys
    Created Owner UUID 2a602183-aee8-4998-a313-25635405d554
    Creating secure boot keys...✓
    Secure boot keys created!
    ```

1. Generate keys with wrong format and move them to correct location

    ```shell
    openssl ecparam -genkey -name secp384r1 -out db.key && openssl req -new -x509 -key db.key -out db.pem -days 365 -subj "/CN=test"
    openssl ecparam -genkey -name secp384r1 -out PK.key && openssl req -new -x509 -key PK.key -out PK.pem -days 365 -subj "/CN=test"
    openssl ecparam -genkey -name secp384r1 -out KEK.key && openssl req -new -x509 -key KEK.key -out KEK.pem -days 365 -subj "/CN=test"
    mv db.key /usr/share/secureboot/keys/db/
    mv PK.key /usr/share/secureboot/keys/PK/
    mv KEK.key /usr/share/secureboot/keys/KEK/
    ```

1. Enroll generated Secure Boot keys

    ```shell
    $ sbctl enroll-keys --yes-this-might-brick-my-machine
    ```

**Expected result**

`sbctl` should fail to enroll keys

```text
couldn't sync keys
```

### SBO013.001 Check automatic certificate provisioning

**Description**

This test verifies that the automatic certificate provisioning will install
custom keys which will allow booting signed `hello.efi` file

<!--
Fix description in Dasharo docs? There the test conclusion is 'which will make
Ubuntu unbootable` which doesn't happen due to automatic certificate
provisioning but due to erasing all secure boot keys
-->

**Prerequisites**

**Steps**

1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. If applicable disable key provisioning (e.g. AMI BIOS)
1. [Remove Secure Boot keys](./secure-boot-bios.md#remove-all-secure-boot-keys)
1. Save changes and restart platform
1. [Boot SBO013.001/LockDown.efi file](./secure-boot-bios.md#boot-efi-file)
1. Wait until platform reboots automatically
1. [Enable Secure Boot](./secure-boot-bios.md#enable-secure-boot)
1. Save changes and restart
1. [Boot SBO013.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO013.002 Check automatic certificate provisioning KEK certificate

**Description**

This test verifies that automatic certificate provisioning installed expected
KEK certificate

**Prerequisites**

* [SBO013.001](#sbo013001-check-automatic-certificate-provisioning) succeeded

**Steps**

1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. Save changes and restart platform.
1. Boot and log into OS
1. Mount USB drive with tests if it wasn't mounted automatically
1. Export currently enrolled certificate

    ```shell
    mokutil --kek > current_certificate.crt
    ```

1. Compare current KEK certificate with one that should be enrolled.
Replace `<usb/mount>` with path to where USB drive is mounted.

    ```shell
    diff <usb/mount>/SBO013.002/KEK.crt current_certificate.crt --color=always
    ```

**Expected result**

No output or slight format differences e.g.

```diff
1c1,2
< SHA1 Fingerprint=EA:EF:F4:8A:C2:38:CB:31:98:FD:45:81:6D:64:99:78:61:BB:B7:0C
---
> [key 1]
> SHA1 Fingerprint: ea:ef:f4:8a:c2:38:cb:31:98:fd:45:81:6d:64:99:78:61:bb:b7:0c
8c9
<         Issuer: CN = KEK Certificate
---
>         Issuer: CN=KEK Certificate
12c13
<         Subject: CN = KEK Certificate
---
>         Subject: CN=KEK Certificate
```
