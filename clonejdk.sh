#!/bin/bash
set -e

git clone --depth 1 https://github.com/openjdk/jdk17u openjdk
if [ "$BUILD_IOS" == "1" ]; then
  # Hack: exclude building macOS stuff
  desktop_mac=openjdk/src/java.desktop/macosx
  mv ${desktop_mac} ${desktop_mac}_NOTIOS
  mkdir -p ${desktop_mac}/native
  mv ${desktop_mac}_NOTIOS/native/libjsound ${desktop_mac}/native/
fi
