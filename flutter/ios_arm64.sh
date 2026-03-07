#!/usr/bin/env bash
FEATURES="flutter,hwcodec"
[ -n "$MARVADESK_VARIANT" ] && FEATURES="${FEATURES},marvadesk_${MARVADESK_VARIANT}"
cargo build --features "$FEATURES" --release --target aarch64-apple-ios --lib
