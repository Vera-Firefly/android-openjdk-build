#!/bin/bash
set -e

# TODO: use jdk17u repo for building for Android
if [ "$BUILD_IOS" != "1" ]; then
  git clone --depth 1 https://github.com/PojavLauncherTeam/mobile openjdk
else
  git clone --depth 1 https://github.com/PojavLauncherTeam/jdk17u openjdk
  # Hack: exclude building macOS stuff
  desktop_mac=openjdk/src/java.desktop/macosx
  mv ${desktop_mac} ${desktop_mac}_NOTIOS
  mkdir -p ${desktop_mac}/native
  mv ${desktop_mac}_NOTIOS/native/libjsound ${desktop_mac}/native/
fi
