#!/bin/bash

#
# by TS, May 2019
#

# @param string $1 Path
# @param int $2 Recursion level
#
# @return string Absolute path
function realpath_osx() {
	local TMP_RP_OSX_RES=
	[[ $1 = /* ]] && TMP_RP_OSX_RES="$1" || TMP_RP_OSX_RES="$PWD/${1#./}"

	if [ -h "$TMP_RP_OSX_RES" ]; then
		TMP_RP_OSX_RES="$(readlink "$TMP_RP_OSX_RES")"
		# possible infinite loop...
		local TMP_RP_OSX_RECLEV=$2
		[ -z "$TMP_RP_OSX_RECLEV" ] && TMP_RP_OSX_RECLEV=0
		TMP_RP_OSX_RECLEV=$(( TMP_RP_OSX_RECLEV + 1 ))
		if [ $TMP_RP_OSX_RECLEV -gt 20 ]; then
			# too much recursion
			TMP_RP_OSX_RES="--error--"
		else
			TMP_RP_OSX_RES="$(realpath_osx "$TMP_RP_OSX_RES" $TMP_RP_OSX_RECLEV)"
		fi
	fi
	echo "$TMP_RP_OSX_RES"
}

# @param string $1 Path
#
# @return string Absolute path
function realpath_poly() {
	case "$OSTYPE" in
		linux*) realpath "$1" ;;
		darwin*) realpath_osx "$1" ;;
		*) echo "$VAR_MYNAME: Error: Unknown OSTYPE '$OSTYPE'" >/dev/stderr; echo -n "$1" ;;
	esac
}

VAR_MYNAME="$(basename "$0")"
VAR_MYDIR="$(realpath_poly "$0")"
VAR_MYDIR="$(dirname "$VAR_MYDIR")"

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
			if [ "$1" = "debian_dist" ]; then
				echo -n "i386"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		aarch64*)
			if [ "$1" = "debian_dist" ]; then
				echo -n "arm64"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		armv7*)
			if [ "$1" = "debian_dist" ]; then
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

function printUsageAndExit() {
	echo "Usage: $VAR_MYNAME" >/dev/stderr
	echo "Example: $VAR_MYNAME" >/dev/stderr
	exit 1
}

cd "$VAR_MYDIR" || exit 1

if [ $# -ne 0 ]; then
	printUsageAndExit
fi

# ----------------------------------------------------------

LVAR_REPO_PREFIX="tsle"
LVAR_IMAGE_NAME="app-jinja2-$(_getCpuArch debian_dist)"
LVAR_JINJA2_VER="latest"

LVAR_IMG_FULL="${LVAR_IMAGE_NAME}:${LVAR_JINJA2_VER}"

# ----------------------------------------------------------

# @param string $1 Docker Image name
# @param string $2 optional: Docker Image version
#
# @returns int If Docker Image exists 0, otherwise 1
function _getDoesDockerImageExist() {
	local TMP_SEARCH="$1"
	[ -n "$2" ] && TMP_SEARCH="$TMP_SEARCH:$2"
	local TMP_AWK="$(echo -n "$1" | sed -e 's/\//\\\//g')"
	#echo "  checking '$TMP_SEARCH'"
	local TMP_IMGID="$(docker image ls "$TMP_SEARCH" | awk '/^'$TMP_AWK' / { print $3 }')"
	[ -n "$TMP_IMGID" ] && return 0 || return 1
}

_getDoesDockerImageExist "$LVAR_IMAGE_NAME" "$LVAR_JINJA2_VER"
if [ $? -ne 0 ]; then
	LVAR_IMG_FULL="${LVAR_REPO_PREFIX}/$LVAR_IMG_FULL"
	_getDoesDockerImageExist "${LVAR_REPO_PREFIX}/${LVAR_IMAGE_NAME}" "$LVAR_JINJA2_VER"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Trying to pull image from repository '${LVAR_REPO_PREFIX}/'..."
		docker pull ${LVAR_IMG_FULL}
		if [ $? -ne 0 ]; then
			echo "$VAR_MYNAME: Error: could not pull image '${LVAR_IMG_FULL}'. Aborting." >/dev/stderr
			exit 1
		fi
	fi
fi

# ----------------------------------------------------------

LCFG_APPDIR="mpapp"

function _compileJ2() {
	docker run \
			--rm \
			-v "$VAR_MYDIR/${LCFG_APPDIR}":"/root/app" \
			$LVAR_IMG_FULL \
			j2 $@
}

# ----------------------------------------------------------

LVAR_ES_VERSION="5.6.13"

LVAR_TEMPL_INP_FN="Dockerfile-${LVAR_ES_VERSION}.j2"
LVAR_DATA_INP_FN="data.env"
LVAR_DATA_FMT="env"
LVAR_OUTP_FN="Dockerfile-${LVAR_ES_VERSION}"

# ----------------------------------------------------------

if [ ! -f "${LCFG_APPDIR}/${LVAR_TEMPL_INP_FN}" ]; then
	cd "${LCFG_APPDIR}" || exit 1
	./get_original_dockerfile_template.sh "$LVAR_ES_VERSION" || exit 1
	cd ..
fi

# ----------------------------------------------------------

if [ ! -f "${LCFG_APPDIR}/${LVAR_TEMPL_INP_FN}" ]; then
	echo "Template '${LVAR_DATA_INP_FN}' not found. Aborting." >/dev/stderr
	exit 1
fi

echo "Compiling '${LVAR_TEMPL_INP_FN}' to '${LCFG_APPDIR}/${LVAR_OUTP_FN}'..."

[ -f "${LCFG_APPDIR}/${LVAR_OUTP_FN}" ] && rm "${LCFG_APPDIR}/${LVAR_OUTP_FN}"

echo "elastic_version=${LVAR_ES_VERSION}" > "${LCFG_APPDIR}/${LVAR_DATA_INP_FN}"
echo "staging_build_num=" >> "${LCFG_APPDIR}/${LVAR_DATA_INP_FN}"
echo "release_manager=" >> "${LCFG_APPDIR}/${LVAR_DATA_INP_FN}"

_compileJ2 -f ${LVAR_DATA_FMT} -o ${LVAR_OUTP_FN} ${LVAR_TEMPL_INP_FN} ${LVAR_DATA_INP_FN}
TMP_RES=$?

rm "${LCFG_APPDIR}/${LVAR_DATA_INP_FN}"

[ $TMP_RES -ne 0 ] && {
	echo "Error: retval=$TMP_RES" >/dev/stderr
	exit 1
}

echo "Done."
