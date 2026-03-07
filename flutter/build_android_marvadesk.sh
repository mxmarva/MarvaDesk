#!/usr/bin/env bash
#
# MarvaDesk Android: build Rust lib and Flutter APK with the SAME variant.
# Usage: bash flutter/build_android_marvadesk.sh <cliente|agente> [abi...]
#   If no ABI list, builds arm64-v8a, armeabi-v7a, x86_64, x86.
#   Example: bash flutter/build_android_marvadesk.sh cliente
#   Example: bash flutter/build_android_marvadesk.sh agente arm64-v8a
#
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANT="${1:-}"
if [ "$VARIANT" != "cliente" ] && [ "$VARIANT" != "agente" ]; then
	echo "Usage: $0 <cliente|agente> [abi...]" >&2
	echo "  Ensures Rust features and Android flavor match (marvadesk_${VARIANT} + --flavor ${VARIANT})." >&2
	exit 1
fi
export MARVADESK_VARIANT="$VARIANT"
shift || true
ABIS=("$@")
if [ ${#ABIS[@]} -eq 0 ]; then
	ABIS=(arm64-v8a armeabi-v7a x86_64 x86)
fi
cd "$ROOT"
for abi in "${ABIS[@]}"; do
	case "$abi" in
		arm64-v8a) bash flutter/ndk_arm64.sh ;;
		armeabi-v7a) bash flutter/ndk_arm.sh ;;
		x86_64) bash flutter/ndk_x64.sh ;;
		x86) bash flutter/ndk_x86.sh ;;
		*) echo "Unknown ABI: $abi" >&2; exit 1 ;;
	esac
done
cd flutter
flutter build apk --flavor "$VARIANT" --release
echo "Done. APK: build/app/outputs/flutter-apk/app-${VARIANT}-release.apk"
