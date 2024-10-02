# BIOS menu

## Index

### Enable Secure Boot

* [Dasharo](#enable-secure-boot-in-dasharo)
* [AMI](#enable-secure-boot-in-ami)

### Disable Secure Boot

* [Dasharo](#disable-secure-boot-in-dasharo)
* [AMI](#disable-secure-boot-in-ami)

### Enter Secure Boot key management menu

* [Dasharo](#enter-secure-boot-key-management-menu-in-dasharo)
* [AMI](#enter-secure-boot-key-management-menu-in-ami)

### Add Secure Boot Certificate

* [Dasharo](#add-secure-boot-certificate-in-dasharo)
* [AMI](#add-secure-boot-certificate-in-ami)

### Boot EFI file

* [Dasharo](#boot-efi-file-in-dasharo)
* [AMI](#boot-efi-file-in-ami)

### Remove all Secure Boot keys

* [Dasharo](#remove-all-secure-boot-keys-in-dasharo)
* [AMI](#remove-all-secure-boot-keys-in-ami)

### Check enrolled keys

* [Dasharo](#check-enrolled-keys-in-dasharo)
* [AMI](#check-enrolled-keys-in-ami)

## Dasharo

### Enable Secure Boot in Dasharo

1. Enter BIOS Setup Menu
1. Enter `Device Manager` menu
1. Enter `Secure Boot Configuration` menu
1. Select `Enable Secure Boot`

    ```text
    /------------------------------------------------------------------------------\
    |                          Secure Boot Configuration                           |
    \------------------------------------------------------------------------------/

                                                            Enable/Disable the
    Current Secure Boot State  Disabled                   Secure Boot feature
    Enable Secure Boot         [X]                        after platform reset
    Secure Boot Mode           <Standard Mode>
    ```

1. `Current Secure Boot State` should be `Enabled` after rebooting platform

### Disable Secure Boot in Dasharo

1. Enter BIOS Setup Menu
1. Enter `Device Manager` menu
1. Enter `Secure Boot Configuration` menu
1. Deselect `Enable Secure Boot`
1. `Current Secure Boot State` should be `Disabled` after rebooting platform

### Enter Secure Boot key management menu in Dasharo

1. Enter BIOS Setup Menu
1. Enter `Device Manager` menu
1. Enter `Secure Boot Configuration` menu
1. Select `Secure Boot Mode` and choose `Custom Mode`

    ```text
    Secure Boot Mode           <Standard Mode>

                                /------------------\
                                | Standard Mode    |
                                | Custom Mode      |
                                \------------------/
    ```

1. Enter `Advanced Secure Boot Keys Management` menu

### Add Secure Boot Certificate in Dasharo

1. [Enter Secure Boot key management menu](#enter-secure-boot-key-management-menu-in-dasharo)
1. Enter `DB Options` menu
1. Enter `Enroll Signature` menu
1. Enter `Enroll Signature Using File` menu
1. Choose device containing tests. It should be labeled `tests`.

    ```text
    /------------------------------------------------------------------------------\
    |                                File Explorer                                 |
    \------------------------------------------------------------------------------/

    > tests,
    [PciRoot(0x0)/Pci(0x1F,0x2)/Sata(0x0,0xFFFF,0x0)/HD(
    1,GPT,B629C319-9A22-4D85-9026-904C0422BB9E,0x800,0x4
    000)]
    ```

1. Select correct file and press enter

    ```text
    /------------------------------------------------------------------------------\
    |                                File Explorer                                 |
    \------------------------------------------------------------------------------/

    > ***NEW FILE***
    > ***NEW FOLDER***

    > <SBO003.001>
    > <SBO004.001>
    > <SBO008.001>
    > <SBO009.001>
    > <SBO010.001>
    > <SBO010.002>
    > <SBO010.003>
    > <SBO010.004>
    > <SBO010.005>
    > <SBO010.006>
    > <SBO011.001>
                                                        v
    /------------------------------------------------------------------------------\
    ```

    ```text
    /------------------------------------------------------------------------------\
    |                                File Explorer                                 |
    \------------------------------------------------------------------------------/

    > ***NEW FILE***
    > ***NEW FOLDER***

    > <.>
    > <..>
    cert.der
    hello.efi
    ```

1. Select `Commit Changes and Exit` and press enter

    ```text
    /------------------------------------------------------------------------------\
    |                              Enroll Signature                                |
    \------------------------------------------------------------------------------/

                                                            Commit Changes and
    > Enroll Signature Using File                           Exit

    cert.der

    Signature GUID             _


    > Commit Changes and Exit
    > Discard Changes and Exit

    /------------------------------------------------------------------------------\
    ```

### Boot EFI file in Dasharo

1. Enter BIOS setup menu
1. Enter `One Time Boot` menu
1. Choose boot entry you want to boot.

    ```text
    /------------------------------------------------------------------------------\
    |                                One Time Boot                                 |
    \------------------------------------------------------------------------------/

    SBO013.001/hello.efi                                  Device Path :
    SBO013.001/LockDown.efi                               HD(1,GPT,B629C319-9A22
    SBO011.001/hello.efi                                  -4D85-9026-904C0422BB9
    SBO010.006/hello.efi                                  E,0x800,0x4000)/SBO003
    SBO010.005/hello.efi                                  .001\hello.efi
    SBO010.004/hello.efi
    SBO010.003/hello.efi
    SBO010.002/hello.efi
    SBO010.001/hello.efi
    SBO009.001/hello.efi
    SBO008.001/hello.efi
    SBO004.001/hello.efi
    SBO003.001/hello.efi
                                                        v
    /------------------------------------------------------------------------------\
    ```

### Remove all Secure Boot keys in Dasharo

1. [Enter Secure Boot key management menu](#enter-secure-boot-key-management-menu-in-dasharo)
1. Select `Erase all Secure Boot Keys` and press enter
1. Accept prompt

    ```text
    /---------------------------------------------------------------------\
    |                                INFO                                 |
    |---------------------------------------------------------------------|
    |Secure Boot Keys & databases will be erased and Secure Boot disabled.|
    |                            Are you sure?                            |
    |                                                                     |
    |                  [ Yes ]                    [ No ]                  |
    \---------------------------------------------------------------------/
    ```

### Check enrolled keys in Dasharo

1. [Enter Secure Boot key management menu](#enter-secure-boot-key-management-menu-in-dasharo)
1. Enter `<x> Options` where `<x>` is key type you want to verify
1. Select `Delete Signature`.
1. You should see GUIDs of enrolled keys

    ```text
    /------------------------------------------------------------------------------\
    |                              Delete Signature                                |
    \------------------------------------------------------------------------------/

    8BE4DF61-93CA-11D2-AA0D-00 [ ]                        PKCS7_GUID
    E098032B8C
    ```

1. Press `ESC` to exit

## AMI

### Enable Secure Boot in AMI

1. Enter BIOS Setup Menu
1. Go to `Security` tab
1. Enter `Secure Boot` menu
1. Set `Secure Boot` Option to `Enabled`

    ```text
                        Aptio Setup - AMI
                            Security
    ┌────────────────────────────────────────────────────┐
    │  System Mode              User                     │
    │                                                    │
    │  Secure Boot              [Enabled]                │
    │                           Active                   │
    │                                                    │
    │  Secure Boot Mode         [Custom]                 │
    │► Restore Factory Keys                              │
    │► Reset To Setup Mode       ┌─── Secure Boot ────┐  │
    │                            │ Disabled           │  │
    │► Key Management            │ Enabled            │  │
    │                            └────────────────────┘  │
    │                                                    │
    │                                                    │
    └────────────────────────────────────────────────────┘
    ```

1. Secure Boot should be `Active` after saving changes and rebooting

### Disable Secure Boot in AMI

1. Enter BIOS Setup Menu
1. Go to `Security` tab
1. Enter `Secure Boot` menu
1. Set `Secure Boot` Option to `Disabled`
1. Secure Boot should be `Not Active` after saving changes and rebooting

### Enter Secure Boot key management menu in AMI

1. Enter BIOS Setup Menu
1. Go to `Security` tab
1. Enter `Secure Boot` menu
1. Make sure that `Secure Boot Mode` is set to `Custom`
1. Enter `Key Management` menu

### Add Secure Boot Certificate in AMI

To add DB certificate:

1. [Enter Secure Boot key management menu](#enter-secure-boot-key-management-menu-in-ami)
1. Enter `Authorized Signatures (db)` menu

    ```text
    │  Secure Boot variable      | Size| Keys| Key
    │  Source
    │► Platform Key          (PK)| 1575|    1| Factory
    │► Key Exchange Keys    (KEK)| 3066|    2| Factory
    │► Authorized Signatures (db)| 6133|    4| Factory
    ```

1. Choose `Append`

    ```text
    ┌───────────────────────────────────┐
    │     Authorized Signatures (db)    │
    │───────────────────────────────────│
    │ Details                           │
    │ Export                            │
    │ Update                            │
    │ Append                            │
    │ Delete                            │
    └───────────────────────────────────┘
    ```

1. Choose `No` to load from external media

    ```text
    ┌──────────────── Append  ─────────────────┐
    │                                          │
    │ Press 'Yes' to load factory default 'db' │
    │         or 'No' to load it from a        │
    │          file on external media          │
    │                                          │
    ├──────────────────────────────────────────┤
    │        Yes                    No         │
    └──────────────────────────────────────────┘
    ```

1. Choose filesystem containing certificate you want to enroll. In case of
pendrive path should contain `USB`

    ```text
    ┌────────────────────────────────────────────────────────────────────────────┐
    │                            Select a File system                            │
    │────────────────────────────────────────────────────────────────────────────│
    │ PciRoot(0x0)/Pci(0x14,0x0)/USB(0x4,0x2)/HD(1,GPT,B629C319-9A22-4D85-9026-9 │
    │ PciRoot(0x0)/Pci(0x1A,0x0)/eMMC(0x0)/HD(2,GPT,8DF343A2-42D9-4198-BB66-C87A │
    └────────────────────────────────────────────────────────────────────────────┘
    ```

1. Select correct file

    ```text
    ┌──────────────────────┐
    │     Select File      │
    │──────────────────────│
    │ add-boot-options.sh ▲│
    │ <SBO013.002>        █│
    │ <SBO013.001>        █│
    │ <SBO011.001>        █│
    │ <SBO010.006>        █│
    │ <SBO010.005>        █│
    │ <SBO010.004>        █│
    │ <SBO010.003>        █│
    │ <SBO010.002>        █│
    │ <SBO010.001>        █│
    │ <SBO009.001>        ░│
    │ <SBO008.001>        ▼│
    └──────────────────────┘
    ```

    ```text
    ┌────────────────────┐
    │    Select File     │
    │────────────────────│
    │ <.>                │
    │ <..>               │
    │ hello.efi          │
    │ cert.der           │
    └────────────────────┘
    ```

1. Select `Public Key Certificate`

    ```text
    ┌──────────────────────────┐
    │    Input File Format     │
    │──────────────────────────│
    │ Public Key Certificate   │
    │ Authenticated Variable   │
    │ EFI PE/COFF Image        │
    └──────────────────────────┘
    ```

1. Accept default owner GUID

    ```text
    ┌──────────────────────────────────────────────────┐
    │           Enter Certificate Owner GUID           │
    │──────────────────────────────────────────────────│
    │   GUID  [26DC4851-195F-4AE1-9A19-FBF883BBB35E]   │
    └──────────────────────────────────────────────────┘
    ```

1. Select `Yes` to enroll certificate

    ```text
    ┌───────────────── Append  ─────────────────┐
    │                                           │
    │  Press 'Yes' to update 'db' with content  │
    │               from cert.der               │
    │                                           │
    ├───────────────────────────────────────────┤
    │        Yes                    No          │
    └───────────────────────────────────────────┘
    ```

If everything went ok you should see

```text
┌── Append  ───┐
│              │
│   Success    │
│              │
├──────────────┤
│      Ok      │
└──────────────┘
```

and that number of keys changed

```text
► Authorized Signatures (db)| 6960|    5| Mixed
```

### Boot EFI file in AMI

1. Enter BIOS setup menu
1. Enter `Save & Exit` tab
1. Choose boot entry you want to boot.

    ```text
    │  Boot Override                                    █│
    │  ubuntu (eMMC PJ3032)                             █│
    │  SBO003.001/hello.efi (PiKVM CD-ROM Drive 0606)   ░│
    │  SBO004.001/hello.efi (PiKVM CD-ROM Drive 0606)   ░│
    │  SBO008.001/hello.efi (PiKVM CD-ROM Drive 0606)   ░│
    ```

### Remove all Secure Boot keys in AMI

1. [Enter Secure Boot Key Management menu](#enter-secure-boot-key-management-menu-in-ami)
1. Choose `Reset To Setup Mode` and choose `Yes`
1. In case you are asked if you want to `reset without saving` you can choose
`No`
1. After that there should be no keys enrolled

    ```text
    ┌────────────────────────────────────────────────────┬
    │  Vendor Keys              Modified                 │
    │                                                    │
    │  Factory Key Provision    [Disabled]               │
    │► Restore Factory Keys                              │
    │► Reset To Setup Mode                               │
    │► Enroll Efi Image                                  │
    │► Export Secure Boot variables                      │
    │                                                    │
    │  Secure Boot variable      | Size| Keys| Key       │
    │  Source                                            │
    │► Platform Key          (PK)|    0|    0| No Keys   │
    │► Key Exchange Keys    (KEK)|    0|    0| No Keys   │
    │► Authorized Signatures (db)|    0|    0| No Keys   │
    │► Forbidden  Signatures(dbx)|    0|    0| No Keys   │
    │► Authorized TimeStamps(dbt)|    0|    0| No Keys   │
    │► OsRecovery Signatures(dbr)|    0|    0| No Keys   │
    └────────────────────────────────────────────────────┘
    ```

### Check enrolled keys in AMI

1. [Enter Secure Boot Key Management menu](#enter-secure-boot-key-management-menu-in-ami)
1. Enter correct menu depending on which key you want to check

    ```text
    |  Secure Boot variable      | Size| Keys| Key
    |  Source
    |> Platform Key          (PK)| 1575|    1| Factory
    |> Key Exchange Keys    (KEK)| 3066|    2| Factory
    |> Authorized Signatures (db)| 6133|    4| Factory
    |> Forbidden  Signatures(dbx)|17836|  371| Factory
    |> Authorized TimeStamps(dbt)|    0|    0| No Keys
    |> OsRecovery Signatures(dbr)|    0|    0| No Keys
    ```

1. Select `Details`

    ```text
    /-----------------------------------\
    |     Authorized Signatures (db)    |
    |-----------------------------------|
    | Details                           |
    | Export                            |
    | Update                            |
    | Append                            |
    | Delete                            |
    \-----------------------------------/
    ```

1. You can select key if you want to see whole GUID

    ```text
    ┌────────────────────────────────────────────────────────────────────────────┐
    │                         Authorized Signatures (db)                         │
    │────────────────────────────────────────────────────────────────────────────│
    │ List| Sig.Type|Count| Size| Owner GUID  | Certificate Legend               │
    │    1|  X.509  |    1| 1448| 77FA9ABD-...| Microsoft UEFI CA 2023           │
    │    2|  X.509  |    1| 1454| 77FA9ABD-...| Windows UEFI CA 2023             │
    │    3|  X.509  |    1| 1556| 77FA9ABD-...| Microsoft Corporation UEFI CA 20 │
    │    4|  X.509  |    1| 1499| 77FA9ABD-...| Microsoft Windows Production PCA │
    │    5|  X.509  |    1|  783| 26DC4851-...| 3mdeb_test                       │
    └────────────────────────────────────────────────────────────────────────────┘
    ```

    ```text
    ┌── Owner GUID  | Certificate Legend ──┐
    │                                      │
    │ 26DC4851-195F-4AE1-9A19-FBF883BBB35E │
    │              3mdeb_test              │
    │                                      │
    └──────────────────────────────────────┘
    ```
