#!/bin/bash

error_check() {
    err=$?
    if [ $err -ne 0 ]; then
        echo "Error: $1"
        exit $err
    fi
}

create_rsa_key() {
    algo=$1
    openssl req -new -x509 -newkey rsa:$algo -subj "/CN=3mdeb_test/" -keyout cert.key -out cert.crt -days 3650 -nodes -sha256 > /dev/null 2>&1
    error_check "Cannot create rsa key pair"
    openssl x509 -in cert.crt -outform der -out cert.der > /dev/null 2>&1
    error_check "Cannot create rsa der cert"
}

create_rsa_key $1
