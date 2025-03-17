#!/bin/bash
set -e
. setdevkitpath.sh

export FREETYPE_DIR=$PWD/freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT
export CUPS_DIR=$PWD/cups
export CFLAGS+=" -DLE_STANDALONE -Wno-int-conversion -Wno-error=implicit-function-declaration" # -I$FREETYPE_DIR -I$CUPS_DI
if [[ "$TARGET_JDK" == "arm" ]]
then
  export CFLAGS+=" -O3 -D__thumb__"
else
  if [[ "$TARGET_JDK" == "x86" ]]; then
     export CFLAGS+=" -O3 -mstackrealign"
  else
     export CFLAGS+=" -O3"
  fi
fi

if [[ "$TARGET_JDK" == "aarch64" ]]
then
   export CFLAGS+=" -march=armv8-a+simd"
fi
   
# if [ "$TARGET_JDK" == "aarch32" ] || [ "$TARGET_JDK" == "aarch64" ]
# then
#   export CFLAGS+=" -march=armv7-a+neon"
# fi

# It isn't good, but need make it build anyways
# cp -R $CUPS_DIR/* $ANDROID_INCLUDE/

# cp -R /usr/include/X11 $ANDROID_INCLUDE/
# cp -R /usr/include/fontconfig $ANDROID_INCLUDE/

ln -s -f /usr/include/X11 $ANDROID_INCLUDE/
ln -s -f /usr/include/fontconfig $ANDROID_INCLUDE/
platform_args="--with-toolchain-type=clang \
  --with-freetype-include=$FREETYPE_DIR/include/freetype2 \
  --with-freetype-lib=$FREETYPE_DIR/lib \
  OBJDUMP=${OBJDUMP} \
  STRIP=${STRIP} \
  NM=${NM} \
  AR=${AR} \
  BUILD_NM=${NM} \
  BUILD_AR=${AR} \
  BUILD_STRIP=$STRIP \
  BUILD_OBJCOPY=$OBJCOPY \
  BUILD_AS="$AS" \
  OBJCOPY=${OBJCOPY} \
  CXXFILT=${CXXFILT} \
  LD=$TOOLCHAIN/bin/ld \
  "

if [[ "$TARGET_JDK" == "x86" ]]; then
    platform_args+="--build=x86_64-unknown-linux-gnu \
    "
fi

AUTOCONF_x11arg="--x-includes=$ANDROID_INCLUDE/X11"
AUTOCONF_EXTRA_ARGS+="OBJCOPY=$OBJCOPY \
  AR=$AR \
  STRIP=$STRIP \
  "

export CFLAGS+=" -DANDROID -D__ANDROID__=1 -pipe -integrated-as -mllvm -polly -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting -mllvm -polly-run-inliner -mllvm -polly-run-dce -fno-semantic-interposition -fvisibility=hidden -mllvm -polly-invariant-load-hoisting -flto=thin -mllvm -polly-run-inliner -mllvm -polly-run-dce -mllvm -polly-parallel -fopenmp=libomp -mllvm -polly-omp-backend=LLVM -mllvm -polly-scheduling=dynamic -flto=thin -fno-emulated-tls -fwhole-program-vtables -fdata-sections -ffunction-sections -fmerge-all-constants -mllvm -hot-cold-split=true -mllvm -polly-detect-keep-going -mllvm -polly-ast-use-context -mllvm -regalloc-enable-priority-advisor=release -mllvm -regalloc-priority-interactive-channel-base=foo"
export LDFLAGS+=" -L$PWD/dummy_libs -fuse-ld=lld" 

# Create dummy libraries so we won't have to remove them in OpenJDK makefiles
mkdir -p dummy_libs
ar cr dummy_libs/libpthread.a
ar cr dummy_libs/librt.a
ar cr dummy_libs/libthread_db.a

# fix building libjawt
ln -s -f $CUPS_DIR/cups $ANDROID_INCLUDE/

cd openjdk

# Apply patches
git reset --hard
git apply --reject --whitespace=fix ../patches/jdk25u_android.diff || echo "git apply failed (Android patch set)"
# git apply --reject --whitespace=fix ../patches/Optimizing.diff || echo "git apply failed (Android patch set)"

# rm -rf build

#   --with-extra-cxxflags="$CXXFLAGS -Dchar16_t=uint16_t -Dchar32_t=uint32_t" \
#   --with-extra-cflags="$CPPFLAGS" \

bash ./configure \
    --with-version-pre="" \
    --with-version-opt="" \
    --with-boot-jdk-jvmargs="-XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:-UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3 -XX:+UseZGC -XX:AllocatePrefetchStyle=1 -XX:-ZProactive -XX:+UseCriticalJavaThreadPriority -XX:+UseSignalChaining -Dfml.ignoreInvalidMinecraftCertificates=true -XX:+UseStringDeduplication -XX:+UseCompressedOops -XX:+UseFastJNIAccessors -XX:+OptimizeStringConcat -XX:+UseThreadPriorities -XX:+EnableJVMCI -XX:+EagerJVMCI -encoding utf-8" \
    --openjdk-target=$TARGET \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --disable-precompiled-headers \
    --disable-warnings-as-errors \
    --enable-option-checking=fatal \
    --enable-headless-only=yes \
    --with-jvm-variants=$JVM_VARIANTS \
    --with-jvm-features=-dtrace,-zero,-vm-structs,link-time-opt,opt-size \
    --with-cups-include=$CUPS_DIR \
    --with-devkit=$TOOLCHAIN \
    --with-native-debug-symbols=external \
    --with-debug-level=$JDK_DEBUG_LEVEL \
    --with-fontconfig-include=$ANDROID_INCLUDE \
    $AUTOCONF_x11arg $AUTOCONF_EXTRA_ARGS \
    --x-libraries=/usr/lib \
        $platform_args || \
error_code=$?
if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi

jobs=$(nproc)

echo Running ${jobs} jobs to build the jdk

cd build/${JVM_PLATFORM}-${TARGET_JDK}-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}
make JOBS=$jobs images || \
error_code=$?
if [[ "$error_code" -ne 0 ]]; then
  echo "Build failure, exited with code $error_code. Trying again."
  make JOBS=$jobs images
fi
