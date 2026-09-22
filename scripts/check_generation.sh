#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${repo_root}/.generation-check.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

"${repo_root}/scripts/generate" >/dev/null
cp -R "${repo_root}/lib/replynodes/generated" "${tmp_dir}/generated-first"
cp "${repo_root}/lib/replynodes/generated.rb" "${tmp_dir}/generated.rb-first"
cp "${repo_root}/lib/replynodes/operation_registry.rb" "${tmp_dir}/registry-first"

"${repo_root}/scripts/generate" >/dev/null
diff -ruN "${tmp_dir}/generated-first" "${repo_root}/lib/replynodes/generated"
diff -u "${tmp_dir}/generated.rb-first" "${repo_root}/lib/replynodes/generated.rb"
diff -u "${tmp_dir}/registry-first" "${repo_root}/lib/replynodes/operation_registry.rb"
echo "generation drift check passed"
