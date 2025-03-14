#!/bin/bash
set -e
. setdevkitpath.sh
cd freetype-$BUILD_FREETYPE_VERSION

echo "Building Freetype"

export PATH=$TOOLCHAIN/bin:$PATH
./configure \
  --host=$TARGET \
  --prefix=${PWD}/build_android-${TARGET_SHORT} \
  LD=$TOOLCHAIN/bin/ld.lld \
  --without-zlib \
  --with-brotli=system \
  --with-png=no \
  --with-harfbuzz=no $EXTRA_ARGS \
  || error_code=$?

if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat ${PWD}/builds/unix/config.log
  exit $error_code
fi

CFLAGS="-O3 -DANDROID -pipe -integrated-as -mllvm -polly -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting -mllvm -polly-run-inliner -mllvm -polly-run-dce -fno-semantic-interposition -fvisibility=hidden -mllvm -polly-invariant-load-hoisting -flto=thin -mllvm -polly-run-inliner -mllvm -polly-run-dce -mllvm -polly-parallel -fopenmp=libomp -mllvm -polly-omp-backend=LLVM -mllvm -polly-scheduling=dynamic -flto=thin -fno-emulated-tls -fwhole-program-vtables -fdata-sections -ffunction-sections -fmerge-all-constants -mllvm -hot-cold-split=true -mllvm -polly-detect-keep-going -mllvm -polly-ast-use-context -mllvm -regalloc-enable-advisor=develop -fno-rtti -march=armv8-a+simd" CXXFLAGS="-O3 -DANDROID -pipe -integrated-as -mllvm -polly -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting -mllvm -polly-run-inliner -mllvm -polly-run-dce -fno-semantic-interposition -fvisibility=hidden -mllvm -polly-invariant-load-hoisting -flto=thin -mllvm -polly-run-inliner -mllvm -polly-run-dce -mllvm -polly-parallel -fopenmp=libomp -mllvm -polly-omp-backend=LLVM -mllvm -polly-scheduling=dynamic -flto=thin -fno-emulated-tls -fwhole-program-vtables -fdata-sections -ffunction-sections -fmerge-all-constants -mllvm -hot-cold-split=true -mllvm -polly-detect-keep-going -mllvm -polly-ast-use-context -mllvm -regalloc-enable-advisor=develop -fno-rtti -march=armv8-a+simd" make -j4
make install
