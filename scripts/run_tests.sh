#!/usr/bin/env bash
# Run every tests/*.vim in a clean Vim and fail on the first sign of trouble.
#
# A test signals failure with `cquit` (non-zero exit). Some Vim errors are
# raised inside a function and do not change the exit code, so the captured
# output is checked for E-codes as well. That is what catches E354 from
# writing the '+' register on builds without clipboard support.
set -u

cd "$(dirname "$0")/.." || exit 1

vim_bin=${VIM_BIN:-vim}
if ! command -v "$vim_bin" >/dev/null 2>&1; then
    echo "vim not found: $vim_bin" >&2
    exit 1
fi

tmp_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp_dir"' EXIT

# Native tools on Windows/MSYS do not understand /tmp paths.
vim_tmp=$tmp_dir
if command -v cygpath >/dev/null 2>&1; then
    vim_tmp=$(cygpath -w "$tmp_dir")
fi

echo "vim: $(command -v "$vim_bin")"
"$vim_bin" -Nu NONE -n -es \
    -c "call writefile(['clipboard=' . has('clipboard') . ' xterm_clipboard=' . has('xterm_clipboard') . ' gui=' . has('gui_running')], '$vim_tmp/features.txt')" \
    -c 'qa!'
cat "$tmp_dir/features.txt"

failed=0
passed=0
for test_file in tests/*.vim; do
    name=$(basename "$test_file")
    log="$tmp_dir/$name.log"
    "$vim_bin" -Nu NONE -n -es -S "$test_file" >"$log" 2>&1
    status=$?
    if [ "$status" -ne 0 ] || grep -qE '(^|[^A-Za-z])E[0-9]{2,4}:|Error detected while processing' "$log"; then
        echo "FAIL $name (exit $status)"
        sed 's/^/    /' "$log"
        failed=$((failed + 1))
    else
        echo "PASS $name"
        passed=$((passed + 1))
    fi
done

echo "---"
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
