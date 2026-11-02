#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"
if command -v swift >/dev/null 2>&1; then
  swift_bin=$(command -v swift)
elif [[ -x /workspace/toolchains/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin/swift ]]; then
  swift_bin=/workspace/toolchains/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin/swift
else
  echo 'Swift 5.9+ is required. On Linux, run scripts/install-linux-swift.sh.' >&2
  exit 1
fi
cache_dir=${PENSION_CACHE_DIR:-/workspace/scratch/pension-swift}
mkdir -p "$cache_dir"
export CLANG_MODULE_CACHE_PATH="$cache_dir/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$cache_dir/modules"
export XDG_CACHE_HOME="$cache_dir/cache"
"$swift_bin" test --jobs 4 --cache-path "$cache_dir/cache" --config-path "$cache_dir/config" --security-path "$cache_dir/security" --scratch-path "$cache_dir/build"
