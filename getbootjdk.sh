#!/bin/bash
set -e
. setdevkitpath.sh

# Temp script to get jdk20
# These cases are hardcoded to:
# - Linux amd64
# - macOS arm64
# Please change if you have different architecture.

wget https://download.java.net/java/GA/jdk20/bdc68b4b9cbc4ebcb30745c85038d91d/36/GPL/openjdk-20_linux-x64_bin.tar.gz
tar xvf openjdk-20*.tar.gz
