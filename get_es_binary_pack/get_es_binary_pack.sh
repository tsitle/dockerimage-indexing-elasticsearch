#!/bin/bash

LVAR_ES_VERSION="$1"

case "$LVAR_ES_VERSION" in
	6.6.2)
		echo -n
		;;
	*)
		echo "Unsupported ES version '$LVAR_ES_VERSION'. Aborting." >/dev/stderr
		exit 1
		;;
esac

LVAR_ES_DIR="elasticsearch-${LVAR_ES_VERSION}"
LVAR_TAR_ORG="${LVAR_ES_DIR}.tgz"

command -v 7zr >/dev/null 2>&1 || {
	echo "7zr not found. Aborting" >/dev/stderr
	exit 1
}

if [ ! -f "$LVAR_TAR_ORG" ]; then
	echo "Getting original tarball..."
	curl -L \
			-o ${LVAR_TAR_ORG} \
			https://artifacts.elastic.co/downloads/elasticsearch/${LVAR_ES_DIR}.tar.gz || exit 1
fi

echo "Extracting original tarball..."
tar xf ${LVAR_TAR_ORG} || exit 1

echo "Creating 7-Zip'ed tarball of..."
tar cf - "${LVAR_ES_DIR}" | 7zr a -si -v45m "${LVAR_ES_DIR}.tar.7z" || exit 1
for TMPFN in *.tar.7z*; do
	md5sum $TMPFN > $TMPFN.md5
done

rm -r ${LVAR_ES_DIR}
