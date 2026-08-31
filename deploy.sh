#!/usr/bin/env bash
#
# deploy.sh — render this Quarto site and publish it to a self-hosted
# nginx/Apache server.
#
# The main site shares a docroot with two separately-built sub-projects
# (ridehail, ridehail-toronto). This script deploys ONLY the main site; each
# sub-project is deployed on its own via its own deploy.sh:
#     ~/src/ridehail-simulation/deploy.sh   ->  /ridehail/
#     ~/src/ridehail-toronto/deploy.sh      ->  /ridehail-toronto/
# Their directories are protected from this sync's --delete with --exclude, so
# re-publishing the main site never wipes them.
#
# Always test first with:   ./deploy.sh --dry-run
#
set -euo pipefail

# ── CONFIG ──────────────────────────────────────────────────────────────
# Destination server and docroot. Examples:
#   SSH_TARGET="tom@example.com"
#   DOCROOT="/var/www/tomslee/"          # absolute path, keep the trailing slash
# SSH_TARGET="tomslee@salticus.web.net"                            # FILL IN: user@host
SSH_TARGET="tomslee@tomslee.net"                            # FILL IN: user@host
DOCROOT="/home/tomslee/public_html"                               # FILL IN: absolute path, trailing slash

# Local render output of THIS site (Quarto default output dir).
SITE_DIR="_site/"
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

# echo ">> Rendering site with Quarto..."
# quarto render

echo ">> Syncing main site to ${SSH_TARGET}:${DOCROOT}"
echo "   (sub-project directories are excluded, so --delete cannot remove them)"
rsync "${RSYNC_OPTS[@]}" \
  --exclude='/ridehail/' \
  --exclude='/ridehail-toronto/' \
  "$SITE_DIR" "${SSH_TARGET}:${DOCROOT}"

echo ">> Done. (Sub-projects deploy separately — see their own deploy.sh.)"
