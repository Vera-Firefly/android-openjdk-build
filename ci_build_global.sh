#!/bin/bash
set -e
. setdevkitpath.sh

export JDK_DEBUG_LEVEL=release

chmod 777 maketoolchain.sh
chmod 777 extractndk.sh

wget -nc -nv -O android-ndk-$NDK_VERSION-linux.zip "https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux.zip"
./extractndk.sh
./maketoolchain.sh

# Some modifies to NDK to fix

chmod 777 getlibs.sh
chmod 777 buildlibs.sh
chmod 777 buildjdk.sh
chmod 777 removejdkdebuginfo.sh
chmod 777 tarjdk.sh
chomd 777 clonejdk.sh

./getlibs.sh
./buildlibs.sh
./clonejdk.sh
./buildjdk.sh
./removejdkdebuginfo.sh
./tarjdk.sh
