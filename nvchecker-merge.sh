#!/usr/bin/env bash
#
# Merge the per-package .nvchecker.toml files into nvchecker_merged.toml and
# nvchecker_flaky_merged.toml, using the [__config__] from nvchecker.toml and
# nvchecker_flaky.toml respectively. Packages listed in nvchecker_flaky.txt go
# into the flaky config, everything else into the regular one.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

mapfile -t flaky < <(grep -v '^\s*$' nvchecker_flaky.txt)

cp nvchecker.toml nvchecker_merged.toml
cp nvchecker_flaky.toml nvchecker_flaky_merged.toml

while IFS= read -r config; do
    pkg="$(dirname "$config")"
    out=nvchecker_merged.toml
    if [[ " ${flaky[*]} " == *" $pkg "* ]]; then
        out=nvchecker_flaky_merged.toml
    fi
    printf '\n' >> "$out"
    cat "$config" >> "$out"
done < <(find . -mindepth 2 -maxdepth 2 -name .nvchecker.toml -printf '%P\n' | sort)

for pkg in "${flaky[@]}"; do
    if [[ ! -f "$pkg/.nvchecker.toml" ]]; then
        echo "error: $pkg is listed in nvchecker_flaky.txt but has no .nvchecker.toml" >&2
        exit 1
    fi
done
