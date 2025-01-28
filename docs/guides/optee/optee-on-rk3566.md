# OPTEE on RK3566

OPTEE is a software stack with security purposes that contains following
elements:
* OPTEE OS;
* OPTEE TAs;
* tee-supplicant;
* Various Linux userspace libraries.

OPTEE OS and OPTEE TAs, could be launched standalone or under hypervisor.

In case of latest 64-bit ARM architectures, there is an additional layer EL3
where secure monitor resides. This secure monitor is a part of ARM TrustZone
(aka. ATZ) future and is responsible for deviding execution environment into two
parts: trusted (aka. TEE) and rich (aka. REE).

The common software stack configuration for embedded ARM devices with ATZ
present is when Linux is running inside REE, but TEE launches some other,
smaller software, that is responsible only for security-related features (e.g.,
secure storage, cryptography). In such cases OPTEE OS could be used inside TEE,
utilizing its well-known and community-supported architecture and good
security-related feature list.

## OPTEE and ATZ on Rockchip SoCs

Rockchip is known for not sharing some of their SoCs security features,
therefore porting OPTEE or ATZ might not be possible. As an alternative Rockchip
gives a repository with binaries for OPTEE OS and ATZ. But these binaries are
known to not boot or work properly. In this guide booting and verification of
the Rockchips bianries for RK3566 will be presented. At the end, there will be
dev notes on how the results were achieved.

### Building Zarhus with ATZ and OPTEE on RK3566



### Tests and verification

OPTEE `xtest` tool results:

```bash

```

Encryption/decryption workflow:

```bash
root@quartz64-a:~# alias p11="pkcs11-tool --module /usr/lib/libckteec.so"
root@quartz64-a:~# p11 --show-info
Cryptoki version 2.40
Manufacturer     Linaro
Library          OP-TEE PKCS11 Cryptoki library (ver 0.1)
Using slot 0 with a present token (0x0)
root@quartz64-a:~# p11 --list-slots
Available slots: 
Slot 0 (0x0): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
Slot 1 (0x1): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
Slot 2 (0x2): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
root@quartz64-a:~# p11 --init-token --label mytoken --so-pin 1234567890
Using slot 0 with a present token (0x0)
Token successfully initialized
root@quartz64-a:~# p11 --label mytoken --login --so-pin 1234567890 --init-pin --pin 12345
Using slot 0 with a present token (0x0)   
User PIN successfully initialized     
root@quartz64-a:~# p11 --list-slots    
Available slots:   
Slot 0 (0x0): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171    
  token label        : mytoken     
  token manufacturer : Linaro  
  token model        : OP-TEE TA
  token flags        : login required, rng, token initialized, PIN initialized, other flags=0x200
  hardware version   : 0.0
  firmware version   : 0.1
  serial num         : 0000000000000000
  pin min/max        : 4/128  
Slot 1 (0x1): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
Slot 2 (0x2): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
root@quartz64-a:~# p11 --list-slots
Available slots:
Slot 0 (0x0): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token label        : mytoken
  token manufacturer : Linaro
  token model        : OP-TEE TA
  token flags        : login required, rng, token initialized, PIN initialized, other flags=0x200
  hardware version   : 0.0
  firmware version   : 0.1
  serial num         : 0000000000000000
  pin min/max        : 4/128
Slot 1 (0x1): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
Slot 2 (0x2): OP-TEE PKCS11 TA - TEE UUID 08b2092e-806a-5e0e-9817-f515c8ff3171
  token state:   uninitialized
root@quartz64-a:~# p11 --list-mechanisms
Using slot 0 with a present token (0x0)
Supported mechanisms:
  SHA512-HMAC, keySize={32,128}, sign, verify
  SHA384-HMAC, keySize={32,128}, sign, verify
  SHA256-HMAC, keySize={24,128}, sign, verify
  SHA224-HMAC, keySize={14,64}, sign, verify
  SHA-1-HMAC, keySize={10,64}, sign, verify
  MD5-HMAC, keySize={8,64}, sign, verify
  SHA512, digest
  SHA384, digest
  SHA256, digest
  SHA224, digest
  SHA-1, digest
  MD5, digest
  GENERIC-SECRET-KEY-GEN, keySize={1,4096}, generate
  AES-KEY-GEN, keySize={16,32}, generate
  AES-CBC-ENCRYPT-DATA, derive
  AES-ECB-ENCRYPT-DATA, derive
  mechtype-0x1089, keySize={16,32}, encrypt, decrypt
  AES-CTR, keySize={16,32}, encrypt, decrypt
  AES-CBC-PAD, keySize={16,32}, encrypt, decrypt
  AES-CBC, keySize={16,32}, encrypt, decrypt
  AES-ECB, keySize={16,32}, encrypt, decrypt
root@quartz64-a:~# p11 -l --pin 12345 --keygen --key-type aes:32 --label mykey --id 1234
Using slot 0 with a present token (0x0)
Key generated:
Secret Key Object; AES length 32
warning: PKCS11 function C_GetAttributeValue(VALUE) failed: rv = CKR_ATTRIBUTE_SENSITIVE (0x11)
  label:      mykey
  ID:         1234
warning: PKCS11 function C_GetAttributeValue(VERIFY_RECOVER) failed: rv = CKR_ATTRIBUTE_TYPE_INVALID (0x12)
  Usage:      encrypt, decrypt
  Access:     never extractable, local
root@quartz64-a:~# p11 --login --pin 12345 --id 1234 --list-objects --type secrkey
Using slot 0 with a present token (0x0)
Secret Key Object; AES length 16
warning: PKCS11 function C_GetAttributeValue(VALUE) failed: rv = CKR_ATTRIBUTE_SENSITIVE (0x11)
  label:      mykey
  ID:         1234
warning: PKCS11 function C_GetAttributeValue(VERIFY_RECOVER) failed: rv = CKR_ATTRIBUTE_TYPE_INVALID (0x12)
  Usage:      encrypt, decrypt
  Access:     never extractable, local
root@quartz64-a:~# dd if=/dev/random bs=32 count=1 of=somefile
1+0 records in
1+0 records out
32 bytes copied, 0.000401625 s, 79.7 kB/s
root@quartz64-a:~# cat somefile
p_�8�q����Jy�(�i��c��Ƹ��X�k��r
root@quartz64-a:~# p11 --login --pin 12345 --encrypt --id 1234 -m AES-ECB -i somefile -o somefile.enc                 
Using slot 0 with a present token (0x0)
Using encrypt algorithm AES-ECB
root@quartz64-a:~# diff somefile somefile.enc 
1c1
< p_�8�q����Jy�(�i��c��Ƹ��X�k��
\ No newline at end of file
---
> ��R'��n|��wd�<*�3�(���H���\^O�
\ No newline at end of file
root@quartz64-a:~# p11 --login --pin 12345 --decrypt --id 1234 -m AES-ECB -i somefile.enc -o somefile.dec      
Using slot 0 with a present token (0x0)
Using decrypt algorithm AES-ECB
root@quartz64-a:~# diff somefile somefile.dec
root@quartz64-a:~#
```

### Dev notes

#### Linking Rockchips ATZ and OPTEE binaries to U-Boot image

Here is `do_prepare_elf` task from `rockchip-rkbin` package:

```bash
do_prepare_elf() {
        install -d ${KEYS_DIRECTORY}
        # Generate key:
        openssl genrsa -out ${KEYS_DIRECTORY}/rsa2048.pem 2048
        openssl rsa -in ${KEYS_DIRECTORY}/rsa2048.pem -pubout -out ${KEYS_DIRECTORY}/rsa2048_pub.pem

        # Embed key into OPTEE OS binary:
        install ${S}/bin/rk35/rk3568_bl32_v*.bin ${WORKDIR}/
        change_puk --teebin ${WORKDIR}/rk3568_bl32_v*.bin --key ${KEYS_DIRECTORY}/rsa2048_pub.pem

        # Create final .elf file:
        cp ${WORKDIR}/rk3568_bl32_v*.bin ${WORKDIR}/tee-rk3566.bin
        aarch64-zarhus-linux-objcopy -B aarch64 -I binary -O elf64-littleaarch64 ${WORKDIR}/tee-rk3566.bin ${WORKDIR}/tee-rk3566.o
        # The 0x08400000 is from here:
        # https://github.com/rockchip-linux/rkbin/blob/0f8ac860f0479da56a1decae207ddc99e289f2e2/RKTRUST/RK3566TRUST_ULTRA.ini#L13
        aarch64-zarhus-linux-ld --entry=0x08400000 ${WORKDIR}/tee-rk3566.o -T ${WORKDIR}/optee.ld -o ${WORKDIR}/tee-rk3566.elf
}
```

The purpose of this function is to link an ELF file from the Rockchips OPTEE OS
binary, because U-Boot expects it in this format. Here **is important** to use
proper entry address. The address from the code above (`--entry=0x08400000`) is
from [Rockchips
`rkbin`](https://github.com/rockchip-linux/rkbin/blob/f43a462e7a1429a9d407ae52b4745033034a6cf9/RKTRUST/RK3566TRUST_ULTRA.ini#L13)
repository. There are addresses for other SoCs too.

Content of the `optee.ld`:

```ld
ENTRY(_binary_tee_rk3566_bin_start);

SECTIONS
{
        . = 0x08400000;
        .data : {
                *(.data)
        }
}
```

#### Linux devicetree integration

For OPTEE OS to work without issues alongise Linux, Linux should know about its
location (`optee_tzdram` from code below) and any kind of shared resources
(`optee_shmem` from code below). These should be declared in Linux devicetree,
here is an example for RK3566:

```dts
/ {
	compatible = "rockchip,rk3566";

	reserved-memory {
		#address-cells = <2>;
		#size-cells = <2>;
		ranges;

		// Memory for OP-TEE OS use only:
		optee_tzdram: optee-tzdram@8400000 {
                       reg = <0x0 0x08400000 0x0 0x00E00000>;
                       no-map;
		};

		// Memory shared between TEE and REE:
		optee_shmem: optee-shmem@9400000 {
                       reg = <0x0 0x09200000 0x0 0x00200000>;
		};
	};

	firmware {
		optee: optee {
			compatible = "linaro,optee-tz";
			method = "smc";
			shm = <&optee_shmem>;
		};
	};
};
```

The probelm is, that Rockchip, while providing the OPTEE OS binary, does not
provide information needed for Linux devicetree configuration and it seems that
the only way to get the inf. is to contact them or try to get it via analysing
the bianries and dumping the shared memory addresses via TA.

#### Adjusting OPTEE Linux stack version

As was mentioned above, OPTEE contains not only the OS and the TAs, but
`tee-supplicant` and libraries too. It is **important**, that those components
are compatible with each other. Rockchips OPTEE binaries are not regularily
updated, therefore some of them may have version that is one or  two years back
to actual OPTEE releases. The version could be checked after the binaries were
linked and booted. Here is U-Boot logs for RK3566 stating OPTEE OS version:

```bash
(...)
INFO:    BL31: Initializing runtime services
INFO:    BL31: Initializing BL32
I/TC:
I/TC: OP-TEE version: 3.13.0-723-gdcfdd61d0 #hisping.lin (gcc version 10.2.1 20201103 (GNU Toolchain for the A-profil4
I/TC: Primary CPU initializing
I/TC: Primary CPU switching to normal world boot
INFO:    BL31: Preparing for EL3 exit to normal world
(...)
```

So, it is `3.13.0` then.

The OPTEE Linux userspace software stack should be downgraded to `3.13.0` too.

!!!  warning

     It was noted, that version `3.18.0` is compatible with the `3.13.0` too,
     but newer versions did not work without issues.
