# Debian Package

This directory builds a Debian package for CoreDNS with the `nat64ptr` plugin compiled in.

The package name is `coredns`. The default package version is read from `coremain/version.go` and suffixed with `-sunoaki`, for example `1.14.4-sunoaki`.

## Build

```sh
packaging/deb/build-deb.sh
```

The output package is written to `dist/`.

Optional overrides:

```sh
VERSION=1.14.4-sunoaki ARCH=amd64 packaging/deb/build-deb.sh
```

## Install

```sh
sudo dpkg -i dist/coredns_1.14.4-sunoaki_amd64.deb
sudo systemctl start coredns
```

The service reads `/etc/coredns/Corefile` and runs as the `coredns` system user.
