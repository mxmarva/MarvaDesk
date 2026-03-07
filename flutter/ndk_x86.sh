#!/usr/bin/env bash

#
# Fix OpenSSL build with Android NDK clang on 32-bit architectures
#

export CFLAGS="-DBROKEN_CLANG_ATOMICS"
export CXXFLAGS="-DBROKEN_CLANG_ATOMICS"

FEATURES="flutter"
[ -n "$MARVADESK_VARIANT" ] && FEATURES="${FEATURES},marvadesk_${MARVADESK_VARIANT}"
cargo ndk --platform 21 --target i686-linux-android build --release --features "$FEATURES"
