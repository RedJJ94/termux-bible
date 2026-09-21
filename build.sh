#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

if ! pandoc_cmd="$(command -v pandoc 2>/dev/null)"; then
    echo "ERROR: pandoc was not found on the PATH." >&2
    echo "       Install pandoc first (for example: pkg install pandoc)." >&2
    exit 1
fi

metadata_file="metadata.yaml"
css_file="epub-style.css"

if [[ ! -f "$metadata_file" ]]; then
    echo "ERROR: metadata file '$metadata_file' not found in '$script_dir'." >&2
    exit 1
fi

if [[ ! -f "$css_file" ]]; then
    echo "ERROR: stylesheet '$css_file' not found in '$script_dir'." >&2
    exit 1
fi

output="${1:-termux-bible.epub}"

sections=(
    "00-foundations"
    "01-termux"
    "02-shell"
    "03-android"
    "04-adb"
    "05-shizuku"
    "06-rish"
    "07-porter"
    "08-power-tools"
    "09-documents-media-data"
    "10-advanced-termux"
    "11-git-github"
    "12-scripting"
    "13-troubleshooting"
    "14-security"
    "15-command-encyclopedia"
    "16-quick-reference"
)

for section in "${sections[@]}" "appendices"; do
    if [[ ! -d "$section" ]]; then
        echo "ERROR: directory '$section' does not exist in '$script_dir'." >&2
        exit 1
    fi
done

inputs=()

for section in "${sections[@]}" "appendices"; do
    while IFS= read -r -d '' file; do
        inputs+=("$file")
    done < <(find "$section" -type f \( -name '*.md' -o -name '*.markdown' \) -print0 | LC_ALL=C sort -z)
done

if [[ ${#inputs[@]} -eq 0 ]]; then
    echo "ERROR: no Markdown files found under the numbered sections or appendices." >&2
    echo "       The EPUB cannot be built without content." >&2
    exit 1
fi

echo "Building '$output' from ${#inputs[@]} Markdown file(s)."
echo "Input order:"
printf '  %s\n' "${inputs[@]}"

if ! "$pandoc_cmd" \
    --from markdown \
    --to epub3 \
    --toc \
    --toc-depth=3 \
    --metadata-file="$metadata_file" \
    --css="$css_file" \
    --output="$output" \
    "${inputs[@]}"
then
    echo "ERROR: pandoc failed while building the EPUB." >&2
    exit 1
fi

echo "EPUB written to '$output'."