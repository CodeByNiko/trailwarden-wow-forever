#!/usr/bin/env bash
# CI only: retain Lua 5.1 verification even when the Ubuntu mirror is unavailable.
set -euo pipefail
if command -v lua5.1 >/dev/null 2>&1; then
  lua5.1 -v
  exit 0
fi
if timeout 45s sudo apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=10 -o Acquire::https::Timeout=10 install -y lua5.1; then
  lua5.1 -v
  exit 0
fi

lua_build_dir=$(mktemp -d)
trap 'rm -rf "$lua_build_dir"' EXIT
curl --fail --location --retry 2 --connect-timeout 10 --max-time 45 \
  https://www.lua.org/ftp/lua-5.1.5.tar.gz -o "$lua_build_dir/lua.tar.gz"
# Published SHA-256: https://www.lua.org/ftp/
printf '%s  %s\n' 2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333 "$lua_build_dir/lua.tar.gz" | sha256sum --check -
tar -xzf "$lua_build_dir/lua.tar.gz" -C "$lua_build_dir"
make -C "$lua_build_dir/lua-5.1.5" generic -j2
sudo install -m 0755 "$lua_build_dir/lua-5.1.5/src/lua" /usr/local/bin/lua5.1
lua5.1 -v
