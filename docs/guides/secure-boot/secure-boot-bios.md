# BIOS menu

## Index

### Enable Secure Boot

* [Dasharo](#enable-secure-boot-in-dasharo)
*

## Dasharo

### Enable Secure Boot in Dasharo

## AMI

### Enable Secure Boot in AMI

1. Enter BIOS Setup Menu
1. Go to `Security` tab
1. Enter `Secure Boot` menu
1. Set `Secure Boot` Option to `Enabled`

    ```text
                                    Aptio Setup - AMI
                                Security
    ┌────────────────────────────────────────────────────┬─────────────────────────┐
    │  System Mode              User                     │Secure Boot feature is   │
    │                                                    │Active if Secure Boot    │
    │  Secure Boot              [Enabled]                │is Enabled,              │
    │                           Active                   │Platform Key(PK) is      │
    │                                                    │enrolled and the System  │
    │  Secure Boot Mode         [Custom]                 │is in User mode.         │
    │► Restore Factory Keys                              │The mode change          │
    │► Reset To Setup Mode       ┌─── Secure Boot ────┐  │requires platform reset  │
    │                            │ Disabled           │  │                         │
    │► Key Management            │ Enabled            │  │─────────────────────────│
    │                            └────────────────────┘  │→←: Select Screen        │
    │                                                    │↑↓: Select Item          │
    │                                                    │Enter: Select            │
    │                                                    │+/-: Change Opt.         │
    │                                                    │F1: General Help         │
    │                                                    │F2: Previous Values      │
    │                                                    │F3: Optimized Defaults   │
    │                                                    │F4: Save & Exit          │
    │                                                    │ESC: Exit                │
    └────────────────────────────────────────────────────┴─────────────────────────┘
    ```

1. Secure Boot should be active after saving changes and rebooting

### Enter Secure Boot Key Management menu in AMI

1. Enter BIOS Setup Menu
1. Go to `Security` tab
1. Enter `Secure Boot` menu
1. Make sure that `Secure Boot Mode` is set to `Custom`
1. Enter `Key Management` menu

### Add Secure Boot Certificate

To add DB certificate:

1. [Enter Secure Boot key management menu](#enter-secure-boot-key-management-menu-in-ami)
1. Enter `Authorized Signatures (db)` menu or `Key Exchange Keys (KEK)`
depending on which certificate you want to enroll

    ```text
    │  Secure Boot variable      | Size| Keys| Key       │                         │
    │  Source                                            │─────────────────────────│
    │► Platform Key          (PK)| 1575|    1| Factory   │→←: Select Screen        │
    │► Key Exchange Keys    (KEK)| 3066|    2| Factory   │↑↓: Select Item          │
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

This assumes that correct boot entry is already present or was added via
`efibootmgr`:

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

### Remove Secure Boot Keys

1. [Enter Secure Boot Key Management menu in AMI](#enter-secure-boot-key-management-menu-in-ami)
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
    ```
