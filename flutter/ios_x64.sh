#!/usr/bin/env bash
FEATURES="flutter"
[ -n "$MARVADESK_VARIANT" ] && FEATURES="${FEATURES},marvadesk_${MARVADESK_VARIANT}"
cargo build --features "$FEATURES" --release --target x86_64-apple-ios --lib
