#!/usr/bin/env ash

set -e

if [[ "$OPENSSL_FIPS" == "1" ]]; then

  # This FIPS installation follows the instructions from the official OpenSSL FIPS User Guide
  # https://openssl-library.org/source/fips-doc/openssl-3.0.9-security-policy-2024-01-12.pdf

  echo "Enabling FIPS"

  # Install required packages
  apk add --no-cache --virtual .build-deps wget make gcc libgcc musl-dev linux-headers perl vim

  # Temporary build directory
  mkdir -p /ossl
  cd /ossl

  # Download and verify the FIPS module
  wget --quiet https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
  echo "$OPENSSL_HASH openssl-$OPENSSL_VERSION.tar.gz" | sha256sum -c - | grep OK
  tar -xzf openssl-$OPENSSL_VERSION.tar.gz

  # Build the fips modules
  cd openssl-$OPENSSL_VERSION
  ./Configure enable-fips --libdir=lib --prefix=/usr
  make

  # Install fips enabled openssl
  make install_fips

  # Update to relink binaries
  apk upgrade --no-cache -U

  # Cleanup
  rm -rf /tmp
  apk del .build-deps
else
  echo "FIPS Disabled"
fi