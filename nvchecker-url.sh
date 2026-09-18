#!/usr/bin/env bash
#
# Print the upstream release URL for <pkgname> <version>, derived from the
# package's .nvchecker.toml. Used by the "Check for updates" workflow
# (.github/workflows/aur.yml) for the body of the update PR. Prints "None" if
# the config has no URL to derive one from.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

pkg=${1:?package name required}
version=${2:?version required}

config="$pkg/.nvchecker.toml"
expr=$(printf '."%s"' "$pkg")

get() {
    tomlq -r "${expr}.$1" "$config"
}

if [[ $(get source) == github ]]; then
    prefix=$(get prefix)
    [[ $prefix != null ]] || prefix=''
    url="https://github.com/$(get github)/releases/tag/${prefix}${version}"
else
    url=$(get release_url)
    [[ $url != null ]] || url=$(get url)
    url=${url//__version__/$version}
fi

[[ -n $url && $url != null ]] || url=None
echo "$url"
