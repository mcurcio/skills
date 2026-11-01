#!/usr/bin/env bash
# verify-quiet.sh — run a (long, noisy) verify/test/build command but keep its output
# OFF the LLM's context. Full output goes to a temp log; only a TINY summary prints to stdout.
#
# Rationale: a passing `npm run verify` emits ~2000 lines an agent would otherwise ingest
# token-by-token to learn one bit (exit 0). This routes that bit programmatically.
#
# Usage:  verify-quiet.sh <command> [args...]
#   e.g.  verify-quiet.sh npm run verify
#         verify-quiet.sh sh -c 'npm run typecheck && cd packages/server && npm test && npm run build'
#
# Contract for the calling agent:
#   - RESULT=PASS    -> exit 0 AND positive test/build evidence found. Trust it; do NOT read the log.
#   - RESULT=UNKNOWN -> exit 0 but NO evidence any test/build actually ran (zero-tests / passWithNoTests
#                       / glob typo). Do NOT trust it — read the printed tail / the LOG.
#   - RESULT=FAIL    -> non-zero exit. Read the printed failure-marker lines + the tail.
# Exit code is the command's real exit code. Fail-safe: never claims PASS without evidence,
# and NEVER filters lines OUT of a failure report (over-filtering can hide the real cause).

LOG="$(mktemp "${TMPDIR:-/tmp}/verify-quiet.XXXXXXXX")"   # X's MUST be at the end (BSD/macOS mktemp)
# Route output through `tee` rather than a plain stdout redirect (`> "$LOG"`).
# Under the sandbox, redirecting a vitest/vite child's stdout to a file triggers a
# 100% crypto.getRandomValues crash (seen in a private project's sandbox);
# a tee pipe keeps stdout a pipe and dodges it. Read the COMMAND's exit (PIPESTATUS[0]),
# not tee's. Requires bash (shebang above), not sh.
"$@" 2>&1 | tee "$LOG" >/dev/null
rc=${PIPESTATUS[0]}
lines=$(wc -l < "$LOG" | tr -d ' ')

# positive evidence that a test/build stage actually ran and reported success
evidence="$(grep -aE "Tests +[0-9]+ passed|Test Files +[0-9]+ passed|passed \([0-9]+\)|Successfully ran target (test|build)|[0-9]+ passing" "$LOG" | tail -3)"

if [ "$rc" -eq 0 ] && [ -n "$evidence" ]; then
  echo "RESULT=PASS  exit=0  (${lines}-line log suppressed)"
  printf '%s\n' "$evidence"
  rm -f "$LOG"   # not needed on a real pass
elif [ "$rc" -eq 0 ]; then
  # exit 0 but nothing proved a suite ran — could be a zero-tests false-green. Do NOT claim PASS.
  echo "RESULT=UNKNOWN  exit=0 but found NO 'Tests N passed' / 'Successfully ran target' evidence."
  echo "Possible zero-tests-run / passWithNoTests / glob typo. Verify manually.  LOG=${LOG}"
  echo "--- last 30 log lines ---"
  tail -30 "$LOG"
else
  echo "RESULT=FAIL  exit=${rc}  LOG=${LOG}  (${lines} lines)"
  # INCLUSIVE failure-marker grep — NO exclude pass (over-filtering can hide the real cause,
  # e.g. a forbidden-import 'boundaries/element-types' error line or an ECONNREFUSED that is real).
  echo "--- failure-marker lines (capped 120) ---"
  grep -anE "error TS[0-9]+|✗|✖|×|[0-9]+ failed|[0-9]+ error(s)?\b|\bFAIL(ED)?\b|npm error|npm ERR|ELIFECYCLE|Failed tasks|Cannot find module|AssertionError|SyntaxError|ReferenceError|TypeError:|is not allowed to import|not allowed to (import|use)" "$LOG" | head -120
  echo "--- last 30 log lines (nx/lerna 'Failed tasks' summary + culprit usually here) ---"
  tail -30 "$LOG"
  echo "--- (full log: ${LOG}) ---"
fi
exit "$rc"
