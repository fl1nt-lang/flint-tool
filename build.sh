#!/bin/sh
# ./build.sh [-O0|-O2] - builds build/flint, the project tool, with flintc: $FLINTC, or the
# flintc in PATH. -O2 (optimized) is the default.
#
# flint is one file and the modules it imports (src/main.fl), so this is a single flintc call.
# Once there's a flint, `flint build --release` builds it the same way (into out/release/).
set -e
cd "$(dirname "$0")"
flintc=${FLINTC:-flintc}
if ! command -v "$flintc" >/dev/null 2>&1; then
  echo "build.sh: no flintc: put it in PATH or set FLINTC=path/to/flintc" >&2
  exit 1
fi
mkdir -p build
"$flintc" build "${1:--O2}" src/main.fl -o build/flint
echo "build/flint"
