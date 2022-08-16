#!/bin/bash
set -e

# TODO: use jdk17u repo for building for Android
if [ "$BUILD_IOS" != "1" ]; then
  git clone --depth 1 https://github.com/PojavLauncherTeam/mobile openjdk
else
  git clone --depth 1 https://github.com/PojavLauncherTeam/jdk17u openjdk
fi
