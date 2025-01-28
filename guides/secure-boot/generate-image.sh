#!/bin/bash

error_exit() {
    _error_msg="$1"
    echo "$_error_msg"
    exit 1
}

error_check() {
    _error_code=$?
    _error_msg="$1"
    [ "$_error_code" -ne 0 ] && error_exit "$_error_msg : ($_error_code)"
    return 0
}

check_using_pkg_mng() {
    # Get the distribution name
    distribution_name=$(lsb_release -is 2>/dev/null || cat /etc/*-release | grep '^ID=' | awk -F= '{print $2}' | tr -d '"')
    error_check "Cannot read information about distribution"

    # Initialize the variable to an empty string
    PKG_MNG=""

    # Map distribution names to package managers
    case "$distribution_name" in
        debian|ubuntu)
            PKG_MNG="apt"
            ;;
        redhat|centos|fedora)
            PKG_MNG="dnf"
            ;;
        arch)
            PKG_MNG="pacman"
            ;;
        openbsd)
            PKG_MNG="pkg"
            ;;
        gentoo)
            PKG_MNG="emerge"
            ;;
        *)
            PKG_MNG="Unknown"
            ;;
    esac

    DISTRO=$distribution_name
    # Display the detected package manager or "Unknown" if none is detected
    if [ "$PKG_MNG" != "Unknown" ]; then
        echo "Detected Package Manager: $PKG_MNG"
        echo "Detected Distro: $DISTRO"
    else
        echo "Unknown Package Manager"
        exit 1
    fi
}

install_deps() {
    local deps=(sbsigntools faketime)
    local deps_test=(sbsign faketime)
    local all_installed="y"

    echo -n "checking dependencies: "
    for dependency in "${deps_test[@]}"; do
        echo -n "$dependency"
        if ! command -v "$dependency" >/dev/null; then
            echo -n "-"
            all_installed="n"
        else
            echo -n "+"
        fi
        echo -n ", "
    done
    echo ""

    if [ $all_installed = "y" ]; then
        return
    fi

    echo "Installing dependencies"
    check_using_pkg_mng

    if [ $DISTRO == "arch" ]; then
        sudo $PKG_MNG -S "${deps[@]}" 2>&1
        error_check "Cannot install ${deps[*]}"
    else
        sudo $PKG_MNG install "${deps[@]}" 2>&1
        error_check "Cannot install ${deps[*]}"
    fi
}

create_rsa_key() {
    algo=$1
    openssl req -new -x509 -newkey rsa:$algo -subj "/CN=3mdeb_test/" -keyout cert.key -out cert.crt -days 3650 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create rsa key pair"
    openssl x509 -in cert.crt -outform der -out cert.der > /dev/null 2>&1
    error_check "Cannot create rsa der cert"
}

create_ecdsa_key() {
    algo=$1
    openssl req -new -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-$algo -subj "/CN=3mdeb_key/" -keyout cert.key -out cert.crt -days 3650 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create ecdsa key pair"
    openssl base64 -d -in cert.crt -out cert.der > /dev/null 2>&1
    error_check "Cannot create ecdsa der cert"
}

create_intermediate_key() {
    # generate two key pairs, make CSR
    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=3mdeb_test/" -keyout cert.key -out cert.crt -days 3650 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create rsa first key for intermediate"
    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=3mdeb_test/" -keyout PK.key -out PK.crt -days 3650 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create rsa first key for intermediate"
    openssl req -new -key cert.key -out cert.csr -subj "/C=PL/O=3mdeb" > /dev/null 2>&1
    error_check "Cannot create csr"
    # sign the CSR with the second key pair
    # its necessary to `touch cert.ext`, otherwise it says its not there
    touch cert.ext
    openssl x509 -req -in cert.csr -CA PK.crt -CAkey PK.key -out cert.crt -CAcreateserial -extfile cert.ext > /dev/null 2>&1
    error_check "Cannot sign csr"
    openssl x509 -in cert.crt -outform der -out cert.der > /dev/null 2>&1
    error_check "Cannot create der from signed cert"
}

create_bad_format_key() {
    algo=$1
    openssl req -new -x509 -newkey rsa:$algo -subj "/CN=3mdeb_test/" -keyout cert.key -out cert.crt -days 3650 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create rsa key pair"
    # here we copy .crt to .der to leave wrong format for BIOS menu
    cp cert.crt cert.der
    error_check "Cannot create fake cert.der"
}

create_expired_cert() {
    faketime '10 days ago' openssl req -new -x509 -newkey rsa:2048 -subj "/CN=ExpiredCert/" -keyout cert.key -out cert.crt -days 10 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create expired rsa key pair"
    openssl x509 -in cert.crt -outform der -out cert.der
    error_check "Cannot create expired rsa der cert"
}

# Create FAT image containing everything in $FILES and create
# `add-boot-options.sh` script
create_iso() {
    IMAGELABEL="tests"
    IMAGEPATH="$TEMPDIR/$IMAGELABEL.img"
    local mounted=
    local dev=
    mounted="/run/media/$(whoami)/$IMAGELABEL"

    dd if=/dev/zero of="$IMAGEPATH" bs=1M count=10 > /dev/null 2>&1
    error_check "Cannot create empty image file to store created certs and efi files"
    # Create GPT table and EFI partition
    fdisk "$IMAGEPATH" << EOF
g
n
1


t
1
w
EOF
    error_check "fdisk failed"

    dev=$(udisksctl loop-setup -f "$IMAGEPATH" | awk '{print substr($NF,1,length($NF)-1)}')
    error_check "udisksctl failed to create loop device"
    trap "udisksctl loop-delete -b $dev; cleanup" EXIT
    echo "Creating fat partition on ${dev}p1"
    sudo mkfs.fat -F 12 "${dev}p1" -n $IMAGELABEL > /dev/null 2>&1
    error_check "Cannot create fat partition"
    mounted=$(udisksctl mount -b "${dev}p1" | awk '{print $NF}')
    error_check "Cannot mount ${dev}p1"
    trap "umount $mounted; udisksctl loop-delete -b $dev; cleanup" EXIT

    # create script that'll add all efi files to boot options
    cat << EOF >> "$FILES/add-boot-options.sh"
#!/bin/bash

UUID=$(lsblk -no UUID "${dev}p1")
PARTITION=\$(basename "\$(realpath "/dev/disk/by-uuid/\$UUID")")
PARTITION_DEV=/dev/\$PARTITION
DEV="/dev/\$(basename "\$(realpath /sys/class/block/\$PARTITION/..)")"
TEMP_FILE=\$(mktemp -d)

mount \$PARTITION_DEV \$TEMP_FILE
cd \$TEMP_FILE
find SBO0* -name "*.efi" -exec \\
    efibootmgr --create --disk=\$DEV --label="{}" \\
                --loader="\$(echo "{}" | sed 's|/|\\\\|g')" \;
EOF

    cp -r "$FILES"/* "$mounted"
    error_check "Couldn't copy $FILES/ to $mounted"

    trap 'cleanup' EXIT
    if ! umount "$mounted"; then
        udisksctl loop-delete -b "$dev"
        error_exit "Failed to umount $mounted"
    fi
    udisksctl loop-delete -b "$dev"
    error_check "Couldn't delete loop device $dev"
}

# create_test <test_name> <sign_efi> <create_key_function> [args...]
create_test() {
    local TEST=$1
    local SIGN="$2"
    shift 2
    mkdir "$TEST"

    pushd "$TEST" >/dev/null || error_exit "Couldn't enter $TEST"

    # call <create_key_function> [args...]
    "$@"
    error_check "$*: Couldn't create keys and certificate"
    if [ "$SIGN" = "y" ]; then
        sbsign --key cert.key --cert cert.crt --output "hello.efi" "$HELLO_EFI"
        error_check "Couldn't sign $HELLO_EFI"
        if [ ! -f "hello.efi" ]; then
            error_exit "Couldn't create signed $TEST/hello.efi"
        fi
    else
        cp "$HELLO_EFI" hello.efi
    fi
    # remove everything except "cert.der" and "hello.efi"
    find -maxdepth 1 -type f ! -name "cert.der" ! -name "hello.efi" -exec rm {} \;
    error_check "find error"

    popd >/dev/null || error_exit "Couldn't popd"
}

# create_provisioning_test <test_name>
create_provisioning_test() {
    local TEST=$1
    local COMMIT=b2c2716c20afa76575b431e0a4cfd126e6df766f
    local DB_CRT_HASH=80aea212df9d1855e00251d80d1b384f9e7d7c48c4d6491f5a346dd52b3c2260
    local DB_KEY_HASH=da2bb57a51a7eb7f701c17d9f7e8ade7668fe204af5518e520580328f7e64231
    mkdir "$TEST"

    pushd "$TEST" >/dev/null || error_exit "Couldn't enter $TEST"

    wget https://raw.githubusercontent.com/Wind-River/meta-secure-core/$COMMIT/meta-signing-key/files/uefi_sb_keys/DB.crt
    wget https://raw.githubusercontent.com/Wind-River/meta-secure-core/$COMMIT/meta-signing-key/files/uefi_sb_keys/DB.key
    if ! diff <(sha256sum DB.crt) <(echo "$DB_CRT_HASH  DB.crt") || \
        ! diff <(sha256sum DB.key) <(echo "$DB_KEY_HASH  DB.key")
    then
        error_exit "Wrong DB.crt/DB.key sha256 hash"
    fi
    cp "$SCRIPTDIR/LockDown.efi" .
    sbsign --key DB.key --cert DB.crt --output "hello.efi" "$HELLO_EFI"
    # remove everything except "LockDown.efi" and "hello.efi"
    find -maxdepth 1 -type f ! -name "LockDown.efi" ! -name "hello.efi" -exec rm {} \;

    popd >/dev/null || error_exit "Couldn't popd"
}

# create_provisioning_kek_test <test_name>
create_provisioning_kek_test() {
    local TEST=$1
    local COMMIT=b2c2716c20afa76575b431e0a4cfd126e6df766f
    local KEK_CRT_HASH=1a67de100cfc909a1a84fc2444e8378a01fe1fecb2cd37a6b4634b10662a21d2
    mkdir "$TEST"

    pushd "$TEST" >/dev/null || error_exit "Couldn't enter $TEST"

    wget https://raw.githubusercontent.com/Wind-River/meta-secure-core/$COMMIT/meta-signing-key/files/uefi_sb_keys/KEK.crt
    if ! diff <(sha256sum KEK.crt) <(echo "$KEK_CRT_HASH  KEK.crt"); then
        error_exit "Wrong KEK.crt sha256 hash"
    fi
    openssl x509 -fingerprint -in KEK.crt -noout -text > KEK2.crt
    mv KEK2.crt KEK.crt

    popd >/dev/null || error_exit "Couldn't popd"
}

cleanup() {
    echo "removing $TEMPDIR"
    rm -r "$TEMPDIR"
}

parse_args() {
    positional_args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                set -x
                ;;
            -*)
                print_usage
                error_exit "Unknown option $1"
                ;;
            *)
                positional_args+=("$1")
                ;;
        esac
        shift
    done
}

print_usage() {
    echo "generate-image.sh [-v]"
}

parse_args "$@"
set -- "${positional_args[@]}"

if [ $# -ne 0 ]; then
    print_usage
    error_exit "Script doesn't accept positional arguments"
fi

SCRIPTDIR=$(readlink -f "$(dirname "$0")")
HELLO_EFI="$(realpath hello.efi)"

TEMPDIR=$(mktemp -d)
trap "cleanup" EXIT

FILES="$TEMPDIR/files"
mkdir "$FILES"
pushd "$FILES" >/dev/null || error_check "Couldn't create $FILES"

install_deps

create_test SBO003.001 y create_rsa_key 2048
create_test SBO004.001 n create_rsa_key 2048
create_test SBO008.001 n create_bad_format_key 2048
create_test SBO009.001 y create_intermediate_key
create_test SBO010.001 y create_rsa_key 2048
create_test SBO010.002 y create_rsa_key 3072
create_test SBO010.003 y create_rsa_key 4096
create_test SBO010.004 y create_ecdsa_key 256
create_test SBO010.005 y create_ecdsa_key 384
create_test SBO010.006 y create_ecdsa_key 521
create_test SBO011.001 y create_expired_cert
create_provisioning_test SBO013.001
create_provisioning_kek_test SBO013.002

echo "creating iso image"
create_iso
cp "$IMAGEPATH" "$SCRIPTDIR"/
error_check "Couldn't copy $IMAGELABEL.img to $SCRIPTDIR"
echo "Done"
popd >/dev/null || error_check "Couldn't go back to original directory"
