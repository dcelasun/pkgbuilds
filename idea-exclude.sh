#!/usr/bin/env bash
#
# Add missing IntelliJ excludeFolder entries for the src/ and pkg/ directories
# of every PKGBUILD in this repo. Idempotent: existing entries are left alone,
# and unrelated excludes are preserved.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
iml="$repo_dir/.idea/pkgbuilds.iml"

if [[ ! -f "$iml" ]]; then
    echo "error: $iml not found" >&2
    exit 1
fi

# Collect the entries we want, two per PKGBUILD directory, that aren't already
# present in the .iml file.
missing=()
while IFS= read -r pkgbuild; do
    dir="$(dirname "$pkgbuild")"
    dir="${dir#./}"
    for sub in pkg src; do
        line="      <excludeFolder url=\"file://\$MODULE_DIR\$/$dir/$sub\" />"
        if ! grep -qF "$line" "$iml"; then
            missing+=("$line")
        fi
    done
done < <(find "$repo_dir" -maxdepth 2 -name PKGBUILD -printf '%P\n' | sort)

if [[ ${#missing[@]} -eq 0 ]]; then
    echo "Nothing to do: all src/ and pkg/ entries already present."
    exit 0
fi

# Insert the missing entries right before the closing </content> tag.
tmp="$(mktemp)"
inserted=0
while IFS= read -r ln; do
    if [[ $inserted -eq 0 && "$ln" == *"</content>"* ]]; then
        printf '%s\n' "${missing[@]}" >> "$tmp"
        inserted=1
    fi
    printf '%s\n' "$ln" >> "$tmp"
done < "$iml"

if [[ $inserted -eq 0 ]]; then
    rm -f "$tmp"
    echo "error: no </content> tag found in $iml" >&2
    exit 1
fi

mv "$tmp" "$iml"
echo "Added ${#missing[@]} entr$([[ ${#missing[@]} -eq 1 ]] && echo y || echo ies) to $iml"
