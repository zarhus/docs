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

create_iso() {
    IMAGELABEL="tests"
    IMAGEPATH="$TEMPDIR/$IMAGELABEL.img"
    local mounted=
    mounted="/run/media/$(whoami)/$IMAGELABEL"

    dd if=/dev/zero of="$IMAGEPATH" bs=1M count=10 > /dev/null 2>&1
    error_check "Cannot create empty image file to store created certs and efi files"
    mkfs.fat -F 12 "$IMAGEPATH" -n $IMAGELABEL > /dev/null 2>&1
    error_check "Cannot assign label: $IMAGELABEL"

    udisksctl loop-setup -f "$IMAGEPATH"
    error_check "Cannot run udisksctl to create iso"
    echo -n "Mounting $IMAGELABEL..."
    while [ ! -d "$mounted" ]; do
        echo -n "."
        sleep 0.2
    done
    echo ""
    trap "umount $mounted; cleanup" EXIT

    # copy everything to the image (except for the image itself)
    cp -r "$FILES"/* "$mounted"
    error_check "Couldn't copy $FILES/ to $mounted"
    trap 'cleanup' EXIT
    umount "$mounted"
    error_check "Couldn't umount $mounted"
}

create_test() {
    # create_test <test_name> <sign_efi> <create_key_function> [args...]
    local TEST=$1
    local SIGN="$2"
    shift 2
    mkdir "$TEST"

    pushd "$TEST" >/dev/null || error_exit "Couldn't enter $TEST"

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

cleanup() {
    echo "removing $TEMPDIR"
    tree $TEMPDIR/files
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
HELLO_EFI="$(mktemp)"
wget -O $HELLO_EFI \
    https://github.com/Dasharo/open-source-firmware-validation/raw/refs/heads/encrypted-rootfs-release-rebase/scripts/secure-boot/generate-images/hello.efi

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

echo "creating iso image"
create_iso
cp "$IMAGEPATH" "$SCRIPTDIR"/
error_check "Couldn't copy $IMAGELABEL.img to $SCRIPTDIR"
echo "Done"
popd >/dev/null || error_check "Couldn't go back to original directory"
