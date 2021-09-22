#!/bin/bash
set -e
. setdevkitpath.sh

if [ "$BUILD_IOS" == "1" ]; then
  export CC=$thecc
  export CXX=$thecxx
  LDFLAGS=-"arch arm64 -isysroot $thesysroot -miphoneos-version-min=12.0"

  echo "Building libffi"
  cd libffi-3.4.2
  python generate-darwin-source-and-headers.py --only-ios
  xcodebuild -arch arm64
  cd build_iphoneos-arm64
  make prefix=`pwd` install
  cd ../..

  echo "Building Freetype"
  cd freetype-$BUILD_FREETYPE_VERSION
  ./configure \
    --host=$TARGET \
    --prefix=${PWD}/build_android-${TARGET_SHORT} \
    --enable-shared=no --enable-static=yes \
    --without-zlib \
    --with-brotli=no \
    --with-png=no \
    --with-harfbuzz=no \
    "CFLAGS=-arch arm64 -pipe -std=c99 -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=12.0 -I$thesysroot/usr/include/libxml2/ -isysroot $thesysroot" \
    AR=/usr/bin/ar \
    "LDFLAGS=$LDFLAGS" \
    || error_code=$?
namefreetype=build_android-${TARGET_SHORT}/lib/libfreetype
else
  export PATH=$TOOLCHAIN/bin:$PATH
  ./configure \
    --host=$TARGET \
    --prefix=`pwd`/build_android-${TARGET_SHORT} \
    --without-zlib \
    --with-png=no \
    --with-harfbuzz=no $EXTRA_ARGS \
    || error_code=$?
fi
if [ "$error_code" -ne 0 ]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi

CFLAGS=-fno-rtti CXXFLAGS=-fno-rtti make -j4
make install

if [ -f "${namefreetype}.a" ]; then
  clang -fPIC -shared $LDFLAGS -lbz2 -Wl,-all_load ${namefreetype}.a -o ${namefreetype}.dylib
fi
