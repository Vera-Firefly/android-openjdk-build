#!/bin/bash
set -e

. setdevkitpath.sh

cp devkit.info.${TARGET_SHORT} $NDK/toolchains/llvm/prebuilt/linux-x86_64
