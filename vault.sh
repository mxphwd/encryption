#!/bin/bash
# Run directly, with bash, or with zsh.
set -eu
umask 077

if ! command -v node >/dev/null 2>&1; then
    printf '%s\n' 'Local Vault needs Node.js 22 or newer on PATH.' >&2
    exit 1
fi

project_dir=$(CDPATH='' cd -P -- "$(dirname -- "$0")" && pwd -P)
exec node "$project_dir/vault.mjs" "$@"
