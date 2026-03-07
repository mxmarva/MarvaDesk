#!/usr/bin/env bash
FEATURES="flutter,hwcodec"
[ -n "$MARVADESK_VARIANT" ] && FEATURES="${FEATURES},marvadesk_${MARVADESK_VARIANT}"
cargo ndk --platform 21 --target armv7-linux-androideabi build --release --features "$FEATURES"
