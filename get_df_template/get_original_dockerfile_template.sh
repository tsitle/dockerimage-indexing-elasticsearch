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

LVAR_ESDOCKER_TAR="dockerfiles.tgz"

if [ -f "${LVAR_ESDOCKER_TAR}" ]; then
	echo "Extracting '${LVAR_ESDOCKER_TAR}'..."
	tar xf "${LVAR_ESDOCKER_TAR}" || exit 1
else
	echo "Cloning git repo..."
	git clone https://github.com/elastic/dockerfiles || exit 1
fi
cd dockerfiles || exit 1
git checkout v$LVAR_ES_VERSION || exit 1

echo "Copying other files for Docker Image..."
[ -d ../files-es ] && rm -r ../files-es
cp -r elasticsearch ../files-es || exit 1

cd ..
if [ ! -f "${LVAR_ESDOCKER_TAR}" ]; then
	echo "Creating '${LVAR_ESDOCKER_TAR}'..."
	tar czf "${LVAR_ESDOCKER_TAR}" dockerfiles || exit 1
fi
[ -d dockerfiles ] && {
	rm -rf dockerfiles || exit 1
}

mv files-es/Dockerfile Dockerfile-$LVAR_ES_VERSION || exit 1

echo

exit 0
