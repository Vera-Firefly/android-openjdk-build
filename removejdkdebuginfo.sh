#!/bin/bash
set -e

. setdevkitpath.sh

imagespath=openjdk/build/${JVM_PLATFORM}-${TARGET_JDK}-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}/images

rm -rf dizout jreout jdkout
mkdir dizout

if [ "$BUILD_IOS" == "1" ]; then
  find $imagespath -name "*.dylib" -exec ldid -Sios-sign-entitlements.xml {} \;
  for bindir in $(find $imagespath -name "bin"); do
    ldid -Sios-sign-entitlements.xml ${bindir}/*
  done
fi

cp freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT/lib/libfreetype.so $imagespath/jdk/lib/

cp -r $imagespath/jdk jdkout

# JDK no longer create separate JRE image, so we have to create one manually.
#mkdir -p jreout/bin
#cp jdkout/bin/{java,jfr,keytool,rmiregistry} jreout/bin/
#cp -r jdkout/{conf,legal,lib,man,release} jreout/
#rm jreout/lib/src.zip

# Produce the jre equivalent from the jdk (https://blog.adoptium.net/2021/10/jlink-to-produce-own-runtime/)
jlink \
--module-path=jdkout/jmods \
--add-modules java.base,java.compiler,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.se,java.security.jgss,java.security.sasl,java.sql,java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.accessibility,jdk.charsets,jdk.crypto.cryptoki,jdk.crypto.ec,jdk.dynalink,jdk.httpserver,jdk.jdwp.agent,jdk.jfr,jdk.jsobject,jdk.localedata,jdk.management,jdk.management.agent,jdk.management.jfr,jdk.naming.dns,jdk.naming.rmi,jdk.net,jdk.nio.mapmode,jdk.sctp,jdk.security.auth,jdk.security.jgss,jdk.unsupported,jdk.xml.dom,jdk.zipfs \
--output jreout \
--strip-debug \
--no-man-pages \
--no-header-files \
--release-info=jdkout/release \
--compress=0

# mv jreout/lib/${TARGET_JDK}/libfontmanager.diz jreout/lib/${TARGET_JDK}/libfontmanager.diz.keep
# find jreout -name "*.debuginfo" | xargs -- rm
# mv jreout/lib/${TARGET_JDK}/libfontmanager.diz.keep jreout/lib/${TARGET_JDK}/libfontmanager.diz

find jdkout -name "*.debuginfo" | xargs -- rm
find jreout -name "*.debuginfo" -exec mv {}   dizout/ \;
