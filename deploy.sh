#!/usr/bin/env bash
#
# deploy.sh — render this Quarto site and publish it to a self-hosted
# nginx/Apache server.
#
# Scenario B, option 1: the main site plus two separately-built sub-projects
# (ridehail, ridehail-toronto) are co-located under a single docroot. The
# sub-project directories are protected from the main-site sync's --delete
# with --exclude, so re-publishing the main site never wipes them.
#
# Fill in the CONFIG section once you have the server address / credentials.
# Always test first with:   ./deploy.sh --dry-run
#
set -euo pipefail

# ── CONFIG ──────────────────────────────────────────────────────────────
# Destination server and docroot. Examples:
#   SSH_TARGET="tom@example.com"
#   DOCROOT="/var/www/tomslee/"          # absolute path, keep the trailing slash
SSH_TARGET=""                            # FILL IN: user@host
DOCROOT=""                               # FILL IN: absolute path, trailing slash

# Local render output of THIS site (Quarto default output dir).
SITE_DIR="_site/"

# Sub-projects to co-locate under the docroot. Each is a separate repo with
# its own build; point SRC at that repo's built output directory and DEST at
# the sub-path it must live under. The sub-path MUST match the base path baked
# into that project's assets (for these two, that is /ridehail/ and
# /ridehail-toronto/). Leave the array empty to skip syncing them from here.
#   format: "SRC_output_dir|subpath"
SUBPROJECTS=(
  # ridehail-toronto is a Quarto site (output dir: _site):
  # "$HOME/src/ridehail-toronto/_site/|ridehail-toronto"
  # ridehail is not checked out locally here — fill in its built output dir:
  # "$HOME/src/ridehail/<output-dir>/|ridehail"
)
# ────────────────────────────────────────────────────────────────────────

RSYNC_OPTS=(-avz --delete --human-readable)
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  RSYNC_OPTS+=(--dry-run)
  echo ">> DRY RUN — no files will be transferred"
fi

if [[ -z "$SSH_TARGET" || -z "$DOCROOT" ]]; then
  echo "ERROR: set SSH_TARGET and DOCROOT in the CONFIG section first." >&2
  exit 1
fi

echo ">> Rendering site with Quarto..."
quarto render

echo ">> Syncing main site to ${SSH_TARGET}:${DOCROOT}"
echo "   (sub-project directories are excluded, so --delete cannot remove them)"
rsync "${RSYNC_OPTS[@]}" \
  --exclude='/ridehail/' \
  --exclude='/ridehail-toronto/' \
  "$SITE_DIR" "${SSH_TARGET}:${DOCROOT}"

for entry in "${SUBPROJECTS[@]}"; do
  src="${entry%%|*}"
  sub="${entry##*|}"
  echo ">> Syncing sub-project '${sub}' from ${src}"
  # No --exclude needed: each sub-project owns its own subtree, so --delete
  # only prunes stale files within that subtree.
  rsync "${RSYNC_OPTS[@]}" "$src" "${SSH_TARGET}:${DOCROOT}${sub}/"
done

echo ">> Done."
