#!/bin/sh
# Runs the pure-JS unit tests headlessly: ./tests/run.sh
#
# Quickshell refuses imports from outside a config's own folder, so the
# harness and the files under test are copied into a scratch folder that
# mirrors the repo layout, and run from there. Exits non-zero on any failure.
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/launcher" "$work/keybinds" "$work/services"
cp "$repo"/launcher/*.js "$work/launcher/"
cp "$repo/keybinds/parse.js" "$work/keybinds/"
cp "$repo/services/Nmcli.js" "$repo/services/Procs.js" "$work/services/"
cp "$repo/tests/shell.qml" "$work/"

# Quickshell has no way to exit from QML, so the timeout ends the run; the
# harness prints DONE once every case has run.
out=$(timeout 5 qs -p "$work" --allow-duplicate --no-color 2>&1 || true)

results=$(printf '%s\n' "$out" | sed -n 's/.*qml: \(PASS\|FAIL\|DONE\)/\1/p')
printf '%s\n' "$results"

if ! printf '%s\n' "$results" | grep -q '^DONE'; then
    echo "Harness did not finish; quickshell said:"
    printf '%s\n' "$out" | grep -E 'ERROR|WARN' | head -20
    exit 1
fi

if printf '%s\n' "$results" | grep -q '^FAIL'; then
    exit 1
fi
