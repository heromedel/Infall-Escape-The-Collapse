#!/bin/bash
# Runs tools/chaos_test.tscn once per seed and prints each run's FAIL lines and summary.
#   tools/chaos.sh [seeds...]           headless (default seeds 1-5)
#   DISPLAY_MODE=xvfb tools/chaos.sh 6  with a virtual display (window resizes and rendering)
#   CHAOS_SECONDS=60 OUT=/some/folder tools/chaos.sh
cd "$(dirname "$0")/.."
out="${OUT:-/tmp/claude-0/chaos}"
mkdir -p "$out"
seeds=("$@")
[ ${#seeds[@]} -eq 0 ] && seeds=(1 2 3 4 5)
budget="${CHAOS_SECONDS:-120}"
for seed in "${seeds[@]}"; do
	log="$out/seed-$seed.log"
	rm -f "$log"
	if [ "${DISPLAY_MODE:-headless}" = "xvfb" ]; then
		CHAOS_SEED=$seed CHAOS_SECONDS=$budget CHAOS_LOG="$log" timeout $((budget + 180)) xvfb-run -a -s "-screen 0 1920x1080x24" \
			godot --path . --rendering-driver opengl3 --resolution 1920x1080 --log-file "$log" tools/chaos_test.tscn > "$out/seed-$seed.out" 2>&1
	else
		CHAOS_SEED=$seed CHAOS_SECONDS=$budget CHAOS_LOG="$log" timeout $((budget + 180)) \
			godot --headless --path . --log-file "$log" tools/chaos_test.tscn > "$out/seed-$seed.out" 2>&1
	fi
	status=$?
	echo "=== seed $seed (exit $status) ==="
	grep -E "^(FAIL|CHAOS)|^  +[0-9]+ x " "$out/seed-$seed.out"
	# A cross-check on the tool's own log scan: every distinct script error in the output
	grep -A1 "SCRIPT ERROR" "$out/seed-$seed.out" | grep -v "^--" | paste - - | sort | uniq -c | sort -rn | head -10
	grep -q "CHAOS DONE" "$out/seed-$seed.out" || echo "FAIL seed $seed did not finish (exit $status): see $out/seed-$seed.out"
done
