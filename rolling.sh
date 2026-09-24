#!/usr/bin/env bash
#
# Helper for the "Update rolling packages" workflow (.github/workflows/rolling.yml).
# Rolling packages are listed in rolling.txt: -git packages, plus
# visual-studio-code-insiders-bin which gets several upstream builds a day and
# sindricad-beta whose rolling "beta" release is rebuilt from main.
#
#   rolling.sh detect [--force] [pkgname]
#       Print a JSON array of rolling packages with upstream changes. With a
#       pkgname, only that package is checked; --force includes it regardless.
#   rolling.sh prepare <pkgname>
#       Update the PKGBUILD of packages whose version isn't computed by
#       pkgver(). Run before makepkg.
#   rolling.sh finalize <pkgname> <old-pkgver> <force>
#       Run after makepkg. Reset or bump pkgrel and print pkgver= and pkgrel=
#       lines for $GITHUB_OUTPUT. pkgver is empty if only pkgrel changed.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

insiders_pkg=visual-studio-code-insiders-bin
sindricad_pkg=sindricad-beta

die() {
    echo "error: $*" >&2
    exit 1
}

pkgbuild_var() {
    awk -F= -v key="$2" '$1 == key {print $2; exit}' "$1/PKGBUILD"
}

# A -git package has changed if the commit hash at the end of its pkgver
# is not a prefix of the latest upstream commit on the tracked branch.
git_changed() {
    local pkg=$1 src url ref=HEAD fragment remote pkgver

    src=$(awk -F' = ' '$1 ~ /^\tsource(_[a-z0-9_]+)?$/ && $2 ~ /^([^:]+::)?git\+/ {print $2; exit}' "$pkg/.SRCINFO")
    [[ -n $src ]] || die "$pkg: no git source in .SRCINFO"

    url=${src#*::}
    url=${url#git+}
    if [[ $url == *'#'* ]]; then
        fragment=${url#*#}
        url=${url%%#*}
        case $fragment in
            branch=*) ref="refs/heads/${fragment#branch=}" ;;
            *) die "$pkg: unsupported source fragment #$fragment" ;;
        esac
    fi
    url=${url%%\?*}

    remote=$(git ls-remote "$url" "$ref" | awk 'NR == 1 {print $1}')
    [[ -n $remote ]] || die "$pkg: could not resolve $ref in $url"

    pkgver=$(pkgbuild_var "$pkg" pkgver)
    [[ $pkgver =~ [.g]([0-9a-f]{7,40})$ ]] || die "$pkg: pkgver $pkgver does not end in a commit hash"

    [[ $remote != "${BASH_REMATCH[1]}"* ]]
}

insiders_url() {
    curl -ILs -o /dev/null -w '%{url_effective}' "https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-$1"
}

# code-insiders_1.124.0-1780966446_amd64.deb -> 1780966446
insiders_version() {
    local file=${1##*/}
    file=${file##*-}
    echo "${file%%_*}"
}

insiders_changed() {
    local version
    version=$(insiders_version "$(insiders_url x64)")
    [[ $version =~ ^[0-9]+$ ]] || die "$insiders_pkg: no version found"
    [[ $version != "$(pkgbuild_var "$insiders_pkg" pkgver)" ]]
}

# The beta tag is fixed, the version is only in the updater manifest
sindricad_version() {
    curl -fsSL https://github.com/MakerViking/sindricad/releases/download/beta/latest.json | jq -r .version
}

sindricad_changed() {
    local version
    version=$(sindricad_version)
    [[ $version =~ ^[0-9.]+$ ]] || die "$sindricad_pkg: no version found"
    [[ $version != "$(pkgbuild_var "$sindricad_pkg" pkgver)" ]]
}

changed() {
    case $1 in
        "$insiders_pkg") insiders_changed ;;
        "$sindricad_pkg") sindricad_changed ;;
        *) git_changed "$1" ;;
    esac
}

cmd_detect() {
    local force=no pkg pkgs=() changed=()

    if [[ ${1:-} == --force ]]; then
        force=yes
        shift
    fi

    if [[ -n ${1:-} ]]; then
        grep -qx "$1" rolling.txt || die "$1 is not listed in rolling.txt"
        pkgs=("$1")
    else
        [[ $force == no ]] || die "--force requires a package name"
        mapfile -t pkgs < <(grep -v '^\s*$' rolling.txt)
    fi

    for pkg in "${pkgs[@]}"; do
        if [[ $force == yes ]]; then
            echo "$pkg: forced" >&2
        elif changed "$pkg"; then
            echo "$pkg: changed" >&2
        else
            echo "$pkg: up to date" >&2
            continue
        fi
        changed+=("$pkg")
    done

    printf '%s\n' "${changed[@]}" | jq -Rnc '[inputs | select(length > 0)]'
}

cmd_prepare() {
    local pkg=${1:?package name required} entry arch_deb arch_pkg url version new_version=''

    if [[ $pkg == "$sindricad_pkg" ]]; then
        version=$(sindricad_version)
        [[ $version =~ ^[0-9.]+$ ]] || die "$pkg: no version found"
        sed -i "s|^pkgver=.*$|pkgver=${version}|" "$pkg/PKGBUILD"
        return 0
    fi

    [[ $pkg == "$insiders_pkg" ]] || return 0

    for entry in x64:x86_64 arm64:aarch64 armhf:armv7h; do
        arch_deb=${entry%%:*}
        arch_pkg=${entry#*:}

        url=$(insiders_url "$arch_deb")
        version=$(insiders_version "$url")
        [[ $version =~ ^[0-9]+$ ]] || die "$pkg: no version found for $arch_deb in $url"

        if [[ $arch_deb == x64 ]]; then
            new_version=$version
        fi

        sed -i "s|^source_${arch_pkg}=.*$|source_${arch_pkg}=(code_${arch_deb}_${version}.deb::${url})|" "$pkg/PKGBUILD"
    done

    sed -i "s|^pkgver=.*$|pkgver=${new_version}|" "$pkg/PKGBUILD"
}

cmd_finalize() {
    local pkg=${1:?package name required} old_pkgver=${2:?old pkgver required} force=${3:-no} pkgver pkgrel

    pkgver=$(pkgbuild_var "$pkg" pkgver)
    pkgrel=$(pkgbuild_var "$pkg" pkgrel)

    if [[ $pkgver != "$old_pkgver" ]]; then
        pkgrel=1
        echo "pkgver=$pkgver"
    elif [[ $force == yes ]]; then
        pkgrel=$((pkgrel + 1))
        echo "pkgver="
    else
        die "$pkg: pkgver is still $old_pkgver after building"
    fi

    sed -i "s|^pkgrel=.*$|pkgrel=${pkgrel}|" "$pkg/PKGBUILD"
    echo "pkgrel=$pkgrel"
}

case ${1:-} in
    detect|prepare|finalize)
        cmd=$1
        shift
        "cmd_$cmd" "$@"
        ;;
    *)
        die "usage: $0 detect [--force] [pkgname] | prepare <pkgname> | finalize <pkgname> <old-pkgver> <force>"
        ;;
esac
