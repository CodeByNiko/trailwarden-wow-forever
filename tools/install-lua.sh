#!/usr/bin/env bash
# CI only: build a pinned Lua 5.1.5 without depending on Ubuntu package mirrors.
set -euo pipefail
if command -v lua5.1 >/dev/null 2>&1 && lua5.1 -e 'assert(_VERSION == "Lua 5.1")'; then
  lua5.1 -v
  exit 0
fi

lua_build_dir=$(mktemp -d)
trap 'rm -rf "$lua_build_dir"' EXIT

download_source() {
  curl --fail --silent --show-error --location --retry 1 --retry-all-errors \
    --connect-timeout 10 --max-time 30 "$1" -o "$lua_build_dir/lua.tar.gz" || return 1
  printf '%s  %s\n' "$2" "$lua_build_dir/lua.tar.gz" | sha256sum --check -
}

# LuaDist's Lua 5.1.5 source mirror, pinned to an immutable commit and archive hash.
# GitHub is already required by checkout; lua.org remains an independent fallback.
if ! download_source \
  https://codeload.github.com/LuaDist/lua/tar.gz/d2e7e7d4d43ff9068b279a617c5b2ca2c2771676 \
  155ae33fa6867ce087200f429895855c261bbd202ec18f76db659c95548d5e40; then
  download_source https://www.lua.org/ftp/lua-5.1.5.tar.gz \
    2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333
fi

mkdir "$lua_build_dir/source"
tar -xzf "$lua_build_dir/lua.tar.gz" -C "$lua_build_dir/source" --strip-components=1
# The mirror preserves the upstream configuration as .orig for its CMake build.
# Use that original header with the upstream generic Makefile.
if [[ ! -f "$lua_build_dir/source/src/luaconf.h" ]]; then
  cp "$lua_build_dir/source/src/luaconf.h.orig" "$lua_build_dir/source/src/luaconf.h"
fi
make -C "$lua_build_dir/source" generic -j2
"$lua_build_dir/source/src/lua" -e 'assert(_VERSION == "Lua 5.1")'
lua_bin_dir="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/trailwarden-lua-5.1/bin"
mkdir -p "$lua_bin_dir"
install -m 0755 "$lua_build_dir/source/src/lua" "$lua_bin_dir/lua5.1"
if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$lua_bin_dir" >> "$GITHUB_PATH"
fi
"$lua_bin_dir/lua5.1" -v
