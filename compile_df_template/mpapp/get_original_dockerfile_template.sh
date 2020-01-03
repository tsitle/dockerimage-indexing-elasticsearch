#!/bin/bash

LVAR_ES_VERSION="$1"

LVAR_ES_GIT_COMMIT=""
case "$LVAR_ES_VERSION" in
	5.6.13)
		LVAR_ES_GIT_COMMIT="4f6fd309ae9fee5e127deeeaeb281330a8b59ed0"
		;;
	*)
		echo "Unsupported ES version '$LVAR_ES_VERSION'. Aborting." >/dev/stderr
		exit 1
		;;
esac

LVAR_ESDOCKER_TAR="elasticsearch-docker.tgz"

if [ -f "${LVAR_ESDOCKER_TAR}" ]; then
	echo "Extracting '${LVAR_ESDOCKER_TAR}'..."
	tar xf "${LVAR_ESDOCKER_TAR}" || exit 1
else
	echo "Cloning git repo..."
	git clone https://github.com/elastic/elasticsearch-docker || exit 1
fi
cd elasticsearch-docker || exit 1
git checkout $LVAR_ES_GIT_COMMIT || exit 1

echo "Copying Dockerfile template..."
cp templates/Dockerfile.j2 ../Dockerfile-${LVAR_ES_VERSION}.j2 || exit 1
echo "Copying other files for Docker Image..."
[ -d ../files-es ] && rm -r ../files-es
cp -r build/elasticsearch ../files-es || exit 1

cd ..
if [ ! -f "${LVAR_ESDOCKER_TAR}" ]; then
	echo "Creating '${LVAR_ESDOCKER_TAR}'..."
	tar czf "${LVAR_ESDOCKER_TAR}" elasticsearch-docker || exit 1
	rm -rf elasticsearch-docker || exit 1
fi

echo

exit 0
