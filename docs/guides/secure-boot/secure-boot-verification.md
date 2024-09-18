# Verifying Secure Boot

## Prerequisites

* Restore BIOS to defaults.
    <!--
    Does it also restore SB keys?
    if not then SBO006.001 + restore should probably be first test so we start
    from known state
    -->
* Attached USB drive prepared in [USB drive](#usb-drive) section

### USB drive

USB directory layout:

```text
.
├── SBO003.001
│   ├── db.cer
│   └── hello.efi
├── SBO004.001
│   └── hello.efi
├── SBO006.001
│   ├── db.cer
│   └── hello.efi
├── SBO008.001
│   ├── db.cer
├── SBO009.001
│   ├── db.cer
│   └── hello.efi
├── SBO010.001
│   ├── db.cer
│   └── hello.efi
├── SBO010.002
│   ├── db.cer
│   └── hello.efi
├── SBO010.003
│   ├── db.cer
│   └── hello.efi
├── SBO010.004
│   ├── db.cer
│   └── hello.efi
├── SBO010.005
│   ├── db.cer
│   └── hello.efi
├── SBO010.006
│   ├── db.cer
│   └── hello.efi
└── SBO011.001
    ├── db.cer
    └── hello.efi
```

## Tests

### SBO002.001 Secure Boot can be enabled from boot menu and is seen from OS

**Description**

This test verifies that Secure Boot can be enabled from the boot menu and, after
the DUT reset, it is seen from the OS.

**Steps**

1. [Enter BIOS setup menu](./secure-boot-bios.md#enter-bios-setup-menu)
1. [Enable Secure Boot](./secure-boot-bios.md#enable-secure-boot)
1. Save changes and reboot DUT
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

1. [Enter BIOS setup menu](./secure-boot-bios.md#enter-bios-setup-menu)
1. [Add SBO003.001/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
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

Screen should show:

```text
Access Denied
```

### SBO006.001 Reset Secure Boot Keys option availability

**Description**

This test aims to verify, that the Reset Secure Boot Keys option is available

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Enter Secure Boot menu](./secure-boot-bios.md#enter-secure-boot-menu)
1. If using Dasharo firmware then
    [enter keys management menu](./secure-boot-bios.md#enter-advanced-secure-boot-keys-management-menu)

**Expected result**

`Reset to default Secure Boot Keys` option should be available

### SBO007.001 Attempt to boot the file after restoring keys to default

**Description**

This test verifies that the Reset Secure Boot Keys option works correctly.

**Prerequisites**

* [SBO003.001](#sbo003001-attempt-to-boot-file-signed-with-the-correct-key)
    succeeded
* [SBO006.001](#sbo006001-reset-secure-boot-keys-option-availability)
    succeeded

**Steps**

1. Select `Reset Secure Boot Keys` options from previous test and accept
1. Save changes and reboot DUT
1. [Boot SBO003.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Access Denied
```

### SBO008.001 Attempt to enroll the key in the incorrect format

**Description**

This test verifies that Secure Boot doesn't allow enrolling keys in the
incorrect format

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO008.001/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)

**Expected result**

```text
ERROR: Unsupported file type!
```

### SBO009.001 Attempt to boot file signed for intermediate certificate

**Description**

This test verifies that a file signed with an intermediate certificate can be
executed.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO009.001/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO009.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

Screen should show:

```text
Hello, world!
```

### SBO010.001 Check support for rsa2k signed certificates

**Description**

This test verifies that a Secure Boot supports RSA2048 signed certificate and
can boot file signed with this certificate.

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO010.001/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO010.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

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

1. [Add SBO010.002/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO010.002/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

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

1. [Add SBO010.003/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO010.003/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

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

1. [Add SBO010.004/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO010.004/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

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

1. [Add SBO010.005/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO010.005/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

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

1. [Add SBO010.006/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO010.006/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

```text
Hello, world!
```

### SBO011.001 Attempt to enroll expired certificate and boot signed image

**Description**

This test verifies that an expired certificate cannot be used to boot image

**Prerequisites**

* [Enabled Secure Boot](./secure-boot-bios.md#enable-secure-boot)

**Steps**

1. [Add SBO011.001/db.cer](./secure-boot-bios.md#add-secure-boot-certificate)
1. Save changes and reboot DUT
1. [Boot SBO011.001/hello.efi file](./secure-boot-bios.md#boot-efi-file)

**Expected result**

```text
Access Denied
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

1. [Remove Secure Boot keys](./secure-boot-bios.md#remove-secure-boot-keys)
1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. Save changes and restart DUT
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

1. Reboot DUT
1. [Enter Secure Boot menu](./secure-boot-bios.md#enter-secure-boot-menu)
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

1. [Remove Secure Boot keys](./secure-boot-bios.md#remove-secure-boot-keys)
1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. Save changes and restart DUT
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

1. Reboot DUT
1. [Enable Secure Boot](./secure-boot-bios.md#enable-secure-boot)
1. Save changes and restart DUT
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

1. [Remove Secure Boot keys](./secure-boot-bios.md#remove-secure-boot-keys)
1. [Disable Secure Boot](./secure-boot-bios.md#disable-secure-boot)
1. Save changes and restart DUT
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

**Prerequisites**

**Steps**

**Expected result**

### SBO013.002 Check automatic certificate provisioning KEK certificate

**Description**

**Prerequisites**

**Steps**

**Expected result**
