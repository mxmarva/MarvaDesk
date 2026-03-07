#!/usr/bin/env bash
FEATURES="flutter"
[ -n "$MARVADESK_VARIANT" ] && FEATURES="${FEATURES},marvadesk_${MARVADESK_VARIANT}"
cargo ndk --platform 21 --target x86_64-linux-android build --release --features "$FEATURES"
