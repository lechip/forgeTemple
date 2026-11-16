#!/usr/bin/env bash
# Writes JOB_DIR/rework-<k>-comment.md: a short PR comment that says what
# changed in one rework. It uses only the job files and git. No model writes it.
#
# Usage: rework-comment.sh <JOB_DIR> <k> <OLD> <NEW>
# Run it in WORK_DIR, so that git sees the job branch.
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: rework-comment.sh <JOB_DIR> <k> <OLD> <NEW>" >&2
  exit 2
fi

job_dir=$1
k=$2
old=$3
new=$4

request="$job_dir/rework-$k.md"
decision="$job_dir/decision.md"
out="$job_dir/rework-$k-comment.md"

for f in "$job_dir/job.json" "$request" "$decision"; do
  [ -f "$f" ] || { echo "missing file: $f" >&2; exit 1; }
done

round=$(sed -n 's/.*"round"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$job_dir/job.json" | head -n 1)
[ -n "$round" ] || { echo "no round in $job_dir/job.json" >&2; exit 1; }

commits=$(git log --oneline "$old..$new")
files=$(git diff --stat "$old..$new")

first_line() {
  if [ -f "$1" ]; then head -n 1 "$1"; else echo "missing"; fi
}

tmp=$(mktemp "$out.XXXXXX")
trap 'rm -f "$tmp"' EXIT

{
  echo "## Rework $k (round $round)"
  echo
  echo "**Request:**"
  echo
  sed 's/^/> /' "$request"
  echo
  echo "**Commits:**"
  echo
  echo '```'
  echo "${commits:-none}"
  echo '```'
  echo
  echo "**Files:**"
  echo
  echo '```'
  echo "${files:-none}"
  echo '```'
  echo
  echo "**Reviews:**"
  echo
  echo "- code: $(first_line "$job_dir/round-$round/review-code.md")"
  echo "- security: $(first_line "$job_dir/round-$round/review-security.md")"
  echo
  echo "**Decision:** $(head -n 1 "$decision")"
  echo
  risk=$(grep -m 1 '^## Risk:' "$decision" | sed 's/^## Risk:[[:space:]]*//' || true)
  echo "**Risk:** ${risk:-missing}"
} > "$tmp"

mv "$tmp" "$out"
trap - EXIT
echo "$out"
