#!/usr/bin/env bash
# Headless simulation wrapper around tools/run_sim.gd (GDD §11).
# Paths in the arguments are relative to the project root.
set -u

cd "$(dirname "$0")/.."

if [ -z "${GODOT:-}" ]; then
	echo "sim: GODOT is not set" >&2
	exit 1
fi

# A clean clone has no global class cache yet.
if [ ! -d .godot ]; then
	"$GODOT" --headless --path . --import > /dev/null 2>&1
fi

"$GODOT" --headless --path . -s res://tools/run_sim.gd -- "$@"
