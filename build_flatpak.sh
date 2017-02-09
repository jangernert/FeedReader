#!/bin/sh

FILE=flatpak/org.gnome.FeedReader.json
VERSION=$(grep "set (VERSION \"" CMakeLists.txt | sed -e 's,set (VERSION ",,' -e 's,"),,')
APPID=`basename $FILE .json`
VERSION_NO_SPACE=$(echo $VERSION | sed -e 's, ,-,')

if [ x$TARGET != x`uname -p` -a ! -z "$TARGET" ]; then
	ARCH_OPT="--arch=$TARGET"
else
	TARGET=`uname -p`
fi

echo ========== Building $APPID ================
rm -rf app
flatpak-builder $ARCH_OPT --ccache --require-changes --repo=hello-repo --subject="${APPID} ${VERSION}" ${EXPORT_ARGS-} app $FILE && \
flatpak build-bundle $ARCH_OPT hello-repo/ $APPID-$VERSION_NO_SPACE.$TARGET.flatpak $APPID master
