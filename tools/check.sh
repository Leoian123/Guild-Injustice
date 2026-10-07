#!/usr/bin/env bash
# Verification gate: import, headless boot with log scan, rule tests.
# Exits non-zero if any of the three steps fails.
set -u

cd "$(dirname "$0")/.."

if [ -z "${GODOT:-}" ]; then
	echo "check: GODOT is not set" >&2
	exit 1
fi

LOG_DIR="reports/raw/check"
mkdir -p "$LOG_DIR"
ERROR_PATTERN='SCRIPT ERROR|Parse Error|Failed to load|^ERROR:'
failed=0

# Prints the offending lines and returns 1 if the log contains engine errors.
scan_log() {
	if grep -nE "$ERROR_PATTERN" "$1"; then
		return 1
	fi
	return 0
}

# Runs one step: name, log file, command...
run_step() {
	local name="$1"
	local log="$2"
	shift 2
	"$@" > "$log" 2>&1
	local rc=$?
	local status="ok"
	if [ $rc -ne 0 ]; then
		status="FAILED (exit $rc)"
	elif ! scan_log "$log"; then
		status="FAILED (errors in log)"
	fi
	echo "check: $name ... $status"
	if [ "$status" != "ok" ]; then
		echo "check: see $log" >&2
		failed=1
		return 1
	fi
	return 0
}

run_step "import" "$LOG_DIR/import.log" \
	"$GODOT" --headless --path . --import

run_step "boot" "$LOG_DIR/boot.log" \
	"$GODOT" --headless --path . --quit-after 10

# GdUnit4 exits 0 on success, 100 on failures, 101 on warnings (orphan nodes):
# anything but 0 fails the gate.
# A hung test (e.g. a loop on a battle that already ended) must fail the gate, not hang it.
TEST_TIMEOUT_SECONDS=300
run_step "tests" "$LOG_DIR/tests.log" \
	timeout "$TEST_TIMEOUT_SECONDS" "$GODOT" --headless --path . \
	-s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	--ignoreHeadlessMode -a res://test -rd res://reports/raw/gdunit

summary=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG_DIR/tests.log" | grep -E 'Overall Summary' | tail -n 1)
echo "check: ${summary:-no test summary found}"
if ! echo "$summary" | grep -qE '[1-9][0-9]* test cases'; then
	echo "check: no test cases were run" >&2
	failed=1
fi

if [ $failed -ne 0 ]; then
	echo "check: FAILED"
	exit 1
fi
echo "check: OK"
