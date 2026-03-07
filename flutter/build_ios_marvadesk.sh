#!/usr/bin/env bash
#
# MarvaDesk iOS/macOS: build Rust lib and Flutter app with the SAME variant.
# Usage: bash flutter/build_ios_marvadesk.sh <cliente|agente>
#   Builds lib for device (arm64) and optionally for simulator (x64).
#
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANT="${1:-}"
if [ "$VARIANT" != "cliente" ] && [ "$VARIANT" != "agente" ]; then
	echo "Usage: $0 <cliente|agente>" >&2
	echo "  Ensures Rust features and app variant match (marvadesk_${VARIANT})." >&2
	exit 1
fi
export MARVADESK_VARIANT="$VARIANT"
cd "$ROOT"
bash flutter/ios_arm64.sh
bash flutter/ios_x64.sh
cd flutter
flutter build ios --release
echo "Done. Open ios/Runner.xcworkspace in Xcode to run or archive."
