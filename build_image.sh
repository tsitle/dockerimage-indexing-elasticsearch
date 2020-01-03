#!/bin/bash

#
# by TS, May 2019
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

# Outputs CPU architecture string
#
# @param string $1 debian_rootfs|debian_dist
#
# @return int EXITCODE
function _getCpuArch() {
	case "$(uname -m)" in
		x86_64*)
			echo -n "amd64"
			;;
		i686*)
			if [ "$1" = "qemu" ]; then
				echo -n "i386"
			elif [ "$1" = "s6_overlay" -o "$1" = "alpine_dist" ]; then
				echo -n "x86"
			else
				echo -n "i386"
			fi
			;;
		aarch64*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm64v8"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "arm64"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		armv7*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm32v7"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "armhf"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown CPU architecture '$(uname -m)'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

_getCpuArch debian_dist >/dev/null || exit 1

# ----------------------------------------------------------

LVAR_DEBIAN_DIST="$(_getCpuArch debian_dist)"
LVAR_DEBIAN_RELEASE="buster"
LVAR_DEBIAN_VERSION="10.02"

LVAR_ES_VERSION="5.6.13"
LVAR_ES_VER_MAJMIN="$(echo -n "$LVAR_ES_VERSION" | cut -f1-2 -d.)"

LVAR_IMAGE_NAME="indexing-elasticsearch-${LVAR_DEBIAN_DIST}"
LVAR_IMAGE_VER="$LVAR_ES_VER_MAJMIN"


# ----------------------------------------------------------

cd build-ctx || exit 1

docker build \
		--build-arg CF_CPUARCH_DEB_DIST="$LVAR_DEBIAN_DIST" \
		--build-arg CF_DEBIAN_RELEASE="$LVAR_DEBIAN_RELEASE" \
		--build-arg CF_DEBIAN_VERSION="$LVAR_DEBIAN_VERSION" \
		--build-arg CF_ES_VERSION="$LVAR_ES_VERSION" \
		-t "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" \
		.
