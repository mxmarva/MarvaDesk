#!/usr/bin/env bash
FEATURES="flutter,hwcodec"
[ -n "$MARVADESK_VARIANT" ] && FEATURES="${FEATURES},marvadesk_${MARVADESK_VARIANT}"
cargo ndk --platform 21 --target aarch64-linux-android build --release --features "$FEATURES"
