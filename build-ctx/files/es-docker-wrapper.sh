#!/bin/bash

#
# by TS, Jan 2020
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------------------

CF_SYSUSR_ES_USER_ID=${CF_SYSUSR_ES_USER_ID:-1000}
CF_SYSUSR_ES_GROUP_ID=${CF_SYSUSR_ES_GROUP_ID:-1000}

# ----------------------------------------------------------

# @param string $1 Username/Groupname
#
# @return void
function _removeUserAndGroup() {
	getent passwd "$1" >/dev/null 2>&1 && userdel -f "$1"
	getent group "$1" >/dev/null 2>&1 && groupdel "$1"
}

# Change numeric IDs of user/group to user-supplied values
#
# @param string $1 Username/Groupname
# @param string $2 Numeric ID for User as string
# @param string $3 Numeric ID for Group as string
# @param string $4 optional: Additional Group-Memberships for User
#
# @return int EXITCODE
function _createUserGroup() {
	local TMP_NID_U="$2"
	local TMP_NID_G="$3"
	echo -n "$TMP_NID_U" | grep -q -E "^[0-9]*$" || {
		echo "$VAR_MYNAME: Error: non-numeric User ID '$TMP_NID_U' supplied for '$1'. Aborting." >/dev/stderr
		return 1
	}
	echo -n "$TMP_NID_G" | grep -q -E "^[0-9]*$" || {
		echo "$VAR_MYNAME: Error: non-numeric Group ID '$TMP_NID_G' supplied '$1'. Aborting." >/dev/stderr
		return 1
	}
	[ ${#TMP_NID_U} -gt 5 ] && {
		echo "$VAR_MYNAME: Error: numeric User ID '$TMP_NID_U' for '$1' has more than five digits. Aborting." >/dev/stderr
		return 1
	}
	[ ${#TMP_NID_G} -gt 5 ] && {
		echo "$VAR_MYNAME: Error: numeric Group ID '$TMP_NID_G' for '$1' has more than five digits. Aborting." >/dev/stderr
		return 1
	}
	[ $TMP_NID_U -eq 0 ] && {
		echo "$VAR_MYNAME: Error: numeric User ID for '$1' may not be 0. Aborting." >/dev/stderr
		return 1
	}
	[ $TMP_NID_G -eq 0 ] && {
		echo "$VAR_MYNAME: Error: numeric Group ID for '$1' may not be 0. Aborting." >/dev/stderr
		return 1
	}

	local TMP_ADD_G="$4"
	if [ -n "$TMP_ADD_G" ]; then
		echo -n "$TMP_ADD_G" | LC_ALL=C grep -q -E "^([0-9a-z_,]|-)*$" || {
			echo "$VAR_MYNAME: Error: additional Group-Memberships '$TMP_ADD_G' container invalid characters. Aborting." >/dev/stderr
			return 1
		}
	fi

	_removeUserAndGroup "$1"

	getent passwd $TMP_NID_U >/dev/null 2>&1 && {
		echo "$VAR_MYNAME: Error: numeric User ID '$TMP_NID_U' already exists. Aborting." >/dev/stderr
		return 1
	}
	getent group $TMP_NID_G >/dev/null 2>&1 && {
		echo "$VAR_MYNAME: Error: numeric Group ID '$TMP_NID_G' already exists. Aborting." >/dev/stderr
		return 1
	}

	local TMP_ARG_ADD_GRPS=""
	[ -n "$TMP_ADD_G" ] && TMP_ARG_ADD_GRPS="-G $TMP_ADD_G"

	echo "$VAR_MYNAME: Setting numeric user/group ID of '$1' to ${TMP_NID_U}/${TMP_NID_G}..."
	groupadd -g ${TMP_NID_G} "$1" || {
		echo "$VAR_MYNAME: Error: could not create Group '$1'. Aborting." >/dev/stderr
		return 1
	}
	useradd -l -u ${TMP_NID_U} -g "$1" $TMP_ARG_ADD_GRPS -M -s /bin/false "$1" || {
		echo "$VAR_MYNAME: Error: could not create User '$1'. Aborting." >/dev/stderr
		return 1
	}
	return 0
}

_createUserGroup "elasticsearch" "${CF_SYSUSR_ES_USER_ID:-0}" "${CF_SYSUSR_ES_GROUP_ID:-0}" || exit 1

# ----------------------------------------------------------------------
# Volumes

# @param string $1 Directory
# @param string $2 User
# @param string $3 Group
# @param string $4 Dir Perms
# @param string $5 File Perms
#
# @return void
function _dep_setOwnerAndPerms_recursive() {
	[ -d "$1" ] && {
		chown $2:$3 -R "$1"
		find "$1" -type d -exec chmod "$4" "{}" \;
		find "$1" -type f -exec chmod "$5" "{}" \;
	}
}

# @param string $1 Directory
# @param string $2 User
# @param string $3 Group
#
# @return void
function _dep_setOwner_recursive() {
	[ -d "$1" ] && {
		chown $2:$3 -R "$1"
	}
}

_dep_setOwner_recursive "." $CF_SYSUSR_ES_USER_ID $CF_SYSUSR_ES_GROUP_ID "750" "640"
#_dep_setOwnerAndPerms_recursive "bin" $CF_SYSUSR_ES_USER_ID $CF_SYSUSR_ES_GROUP_ID "750" "750"

# ----------------------------------------------------------------------

function _replaceHeapSpace_xms() {
	# value= e.g. "-Xms512m"
	sed -e "s/-Xms2g/$1/g" -e "s/-Xms2G/$1/g" -i'' config/jvm.options
}

function _replaceHeapSpace_xmx() {
	# value= e.g. "-Xmx512m"
	sed -e "s/-Xmx2g/$1/g" -e "s/-Xmx2G/$1/g" -i'' config/jvm.options
}

function _replaceHeapSpace() {
	# value= e.g. "-Xms512m -Xmx512m"
	local TMP_OPT1="$(echo -n "$ES_JAVA_OPTS" | cut -f1 -d\ )"
	local TMP_OPT2="$(echo -n "$ES_JAVA_OPTS" | cut -f2 -d\ )"
	echo -n "$TMP_OPT1" | grep -q -e "^-Xms" && _replaceHeapSpace_xms "$TMP_OPT1"
	echo -n "$TMP_OPT1" | grep -q -e "^-Xmx" && _replaceHeapSpace_xmx "$TMP_OPT1"
	echo -n "$TMP_OPT2" | grep -q -e "^-Xms" && _replaceHeapSpace_xms "$TMP_OPT2"
	echo -n "$TMP_OPT2" | grep -q -e "^-Xmx" && _replaceHeapSpace_xmx "$TMP_OPT2"
}

#if [ -n "$ES_JAVA_OPTS" ]; then
#	_replaceHeapSpace
#fi

# ----------------------------------------------------------------------

echo "$VAR_MYNAME: Starting Elasticsearch..."
sudo -u elasticsearch ./bin/es-docker $@
