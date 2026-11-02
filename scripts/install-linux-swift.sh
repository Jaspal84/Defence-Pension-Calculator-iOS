#!/usr/bin/env bash
set -euo pipefail
# Tested on Debian 13 x86_64. Official Ubuntu 22.04 toolchain runs with this image's libraries.
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { echo 'Use native Xcode/Swift on other platforms.' >&2; exit 1; }
base=/workspace/toolchains
release=swift-6.0.3-RELEASE-ubuntu22.04
mkdir -p "$base"
if [[ -x "$base/$release/usr/bin/swift" ]]; then
  "$base/$release/usr/bin/swift" --version
  exit 0
fi
for tool in curl gpg tar; do command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }; done
staging=$(mktemp -d "$base/install.XXXXXXXX")
trap 'rm -rf "$staging"' EXIT
url="https://download.swift.org/swift-6.0.3-release/ubuntu2204/swift-6.0.3-RELEASE/$release.tar.gz"
curl --fail --location --retry 2 "$url" -o "$staging/swift.tar.gz"
curl --fail --location --retry 2 "$url.sig" -o "$staging/swift.tar.gz.sig"
curl --fail --location --retry 2 https://raw.githubusercontent.com/swiftlang/swift-org-website/main/keys/all-keys.asc -o "$staging/keys.asc"
mkdir -m 700 "$staging/gnupg"
gpg --homedir "$staging/gnupg" --batch --import "$staging/keys.asc"
gpg --homedir "$staging/gnupg" --batch --status-fd 1 --verify "$staging/swift.tar.gz.sig" "$staging/swift.tar.gz" > "$staging/signature-status.txt"
# Pin the Swift 6 release signing fingerprint; importing arbitrary new keys cannot authorize an archive.
grep -q '^\[GNUPG:\] VALIDSIG 52BB7E3DE28A71BE22EC05FFEF80A866B47A981F ' "$staging/signature-status.txt"
tar -xzf "$staging/swift.tar.gz" -C "$base"
"$base/$release/usr/bin/swift" --version
